{ lib, pkgs, config, ... }:
# TODO: Kovenna systemd palvelu ja käytä readWritePaths määrettä
# TODO: Lähetä sähköposti jos varmuuskopiointi epäonnistuu
let
  cfg = config.my.services.rsync;
  backup-jobs = lib.attrsets.mapAttrsToList (name: jobcfg: rec {
    jobname = name;
    appname = "rsync-backup-${name}.sh";
    app = pkgs.writeShellApplication {
      name = appname;
      text = let
        destcfg = cfg.destinations."${jobcfg.destination}";
        destination = "${destcfg.username}@${destcfg.host}${destcfg.path}/${jobname}/";
        sources = lib.strings.concatStringsSep " " jobcfg.paths;
        excludes = lib.strings.concatStringsSep " " (builtins.map (ex: "--exclude='${ex}'") jobcfg.excludes);
        precmd = lib.strings.concatStringsSep "\n" (jobcfg.preHooks or []);
        postcmd = lib.strings.concatStringsSep "\n" (jobcfg.postHooks or []);
      in
        ''
          set -e
          RED=$(${pkgs.ncurses}/bin/tput setaf 1)
          GREEN=$(${pkgs.ncurses}/bin/tput setaf 2)
          RESET=$(${pkgs.ncurses}/bin/tput sgr0)

          function cleanup() {
            ${if jobcfg.postHooks != [] then ''echo "''${GREEN}Running backup posthooks...''${RESET}"'' else ""}
            ${postcmd}
            echo "''${GREEN}Finished''${RESET}"
          }

          function onerror() {
            trap - ERR EXIT SIGINT
            echo "''${RED}Backup interrupted, cleaning up...''${RESET}" >&2
            cleanup
            exit
          }

          trap onerror ERR SIGINT
          trap cleanup EXIT

          ${if jobcfg.preHooks != [] then ''echo "''${GREEN}Running backup prehooks...''${RESET}"'' else ""}
          ${precmd}

          echo "''${GREEN}Copy files to remote...''${RESET}"
          ${pkgs.rsync}/bin/rsync -av --no-owner --no-group --delete --delete-excluded \
            --password-file=${destcfg.passwordFile} ${excludes} ${sources} ${destination}
        '';
    };
    binpath = "${app}/bin/${appname}";
  }) cfg.jobs;
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
          destination = lib.mkOption {
            type = lib.types.str;
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

  config.environment.systemPackages = lib.mkIf cfg.enable (builtins.map (job: job.app) backup-jobs);

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
