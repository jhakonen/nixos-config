{ lib, pkgs, config, ... }:
# TODO: Kovenna systemd palvelu ja käytä readWritePaths määrettä
# TODO: Lähetä sähköposti jos varmuuskopiointi epäonnistuu
let
  cfg = config.my.services.rsync;
  backup-jobs = lib.attrsets.mapAttrsToList (name: jobcfg: rec {
    jobname = name;
    appname = "rsync-backup-${name}.sh";
    binpath = "${app}/bin/${appname}";
    app = pkgs.writeShellApplication {
      name = appname;
      text = let
        pre-cmd = lib.strings.concatStringsSep "\n" (jobcfg.preHooks or []);
        post-cmd = lib.strings.concatStringsSep "\n" (jobcfg.postHooks or []);
        merged-destinations = builtins.map (destination-entry:
          if builtins.isString destination-entry then
            {
              username = cfg.destinations."${destination-entry}".username;
              host = cfg.destinations."${destination-entry}".host;
              path = cfg.destinations."${destination-entry}".path;
              password-file = cfg.destinations."${destination-entry}".passwordFile;
              excludes = jobcfg.excludes;
              sources = jobcfg.paths;
            }
          else
            {
              username = cfg.destinations."${destination-entry.destination}".username;
              host = cfg.destinations."${destination-entry.destination}".host;
              path = cfg.destinations."${destination-entry.destination}".path;
              password-file = cfg.destinations."${destination-entry.destination}".passwordFile;
              excludes = jobcfg.excludes ++ destination-entry.excludes;
              sources = jobcfg.paths ++ destination-entry.paths;
            }
        ) jobcfg.destinations;
        rsync-cmds = builtins.map (entry: lib.strings.concatStringsSep " " [
          "${pkgs.rsync}/bin/rsync -av --no-owner --no-group --delete --delete-excluded"
          "--password-file=${entry.password-file}"
          (lib.strings.concatStringsSep " " (builtins.map (ex: "--exclude='${ex}'") entry.excludes))
          (lib.strings.concatStringsSep " " entry.sources)
          "${entry.username}@${entry.host}${entry.path}/${jobname}/"
        ]) merged-destinations;

      in
        ''
          set -e

          if [ -t 1 ]; then IS_TTY=1; else IS_TTY=0; fi
          RED=$(if [ "$IS_TTY" = 1 ]; then ${pkgs.ncurses}/bin/tput setaf 1; fi)
          GREEN=$(if [ "$IS_TTY" = 1 ]; then ${pkgs.ncurses}/bin/tput setaf 2; fi)
          RESET=$(if [ "$IS_TTY" = 1 ]; then ${pkgs.ncurses}/bin/tput sgr0; fi)

          function cleanup() {
            ${if jobcfg.postHooks != [] then ''echo "''${GREEN}Running backup posthooks...''${RESET}"'' else ""}
            ${post-cmd}
            echo "''${GREEN}Finished''${RESET}"
          }

          function onerror() {
            trap - ERR EXIT SIGINT
            echo "''${RED}Backup interrupted, cleaning up...''${RESET}" >&2
            cleanup
            exit 1
          }

          trap onerror ERR SIGINT
          trap cleanup EXIT

          ${if jobcfg.preHooks != [] then ''echo "''${GREEN}Running backup prehooks...''${RESET}"'' else ""}
          ${pre-cmd}

          echo "''${GREEN}Copy files to remote...''${RESET}"
          ${lib.strings.concatStringsSep "\n\n" rsync-cmds}
        '';
    };
  }) cfg.jobs;
  backup-all-app = pkgs.writeShellApplication {
      name = "rsync-backup-all.sh";
      text =
        let
          commands = builtins.map (job: lib.strings.concatStringsSep "\n" [
            ''echo "''${GREEN}Running backup for ${job.jobname}''${RESET}"''
            job.binpath
          ]) backup-jobs;
        in
          ''
            set -e

            if [ -t 1 ]; then IS_TTY=1; else IS_TTY=0; fi
            GREEN=$(if [ "$IS_TTY" = 1 ]; then ${pkgs.ncurses}/bin/tput setaf 2; fi)
            RESET=$(if [ "$IS_TTY" = 1 ]; then ${pkgs.ncurses}/bin/tput sgr0; fi)

            ${lib.strings.concatStringsSep "\n\n" commands}
          '';
    };
in {
  options.my.services.rsync = {
    enable = lib.mkEnableOption "rsync palvelu";
    schedule = lib.mkOption {
      type = lib.types.str;
    };
    destinations = lib.mkOption {
      default = {};
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          username = lib.mkOption {
            type = lib.types.str;
          };
          passwordFile = lib.mkOption {
            type = lib.types.str;
          };
          host = lib.mkOption {
            type = lib.types.str;
          };
          path = lib.mkOption {
            type = lib.types.str;
          };
        };
      });
    };
    jobs = lib.mkOption {
      default = {};
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          destinations = lib.mkOption {
            type = lib.types.listOf (lib.types.oneOf [
              lib.types.str  # destination as str
              (lib.types.submodule {
                options = {
                  destination = lib.mkOption {
                    type = lib.types.str;
                  };
                  excludes = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    default = [];
                  };
                  paths = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    default = [];
                  };
                };
              })
            ]);
          };
          paths = lib.mkOption {
            type = lib.types.listOf lib.types.str;
          };
          excludes = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
          };
          preHooks = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
          };
          postHooks = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
          };
          readWritePaths = lib.mkOption {
            type = lib.types.listOf lib.types.path;
            default = [];
          };
        };
      });
    };
  };

  config.environment.systemPackages = lib.mkIf cfg.enable
    ((builtins.map (job: job.app) backup-jobs) ++ [backup-all-app]);

  config.systemd = lib.mkIf cfg.enable {
    services = builtins.listToAttrs (builtins.map (job: {
      name = "rsync-backup-${job.jobname}";
      value = {
        description = "rsync backup ${job.jobname}";
        enable = true;
        startAt = cfg.schedule;
        script = job.binpath;
        serviceConfig = {
          Type = "oneshot";
        };
      };
    }) backup-jobs);
  };
}
