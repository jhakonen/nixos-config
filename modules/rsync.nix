{ lib, pkgs, config, ... }:
# TODO: Kovenna systemd palvelu ja käytä readWritePaths määrettä
# TODO: Lähetä sähköposti jos varmuuskopiointi epäonnistuu
let
  cfg = config.my.services.rsync;
  state-dir = "/var/libs/rsync-backup-times";
  max-backup-age = 24 * 3; # 3 vuorokautta

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
        hosts = builtins.map (entry: entry.host) merged-destinations;

      in
        ''
          set -e

          if [ -t 1 ]; then IS_TTY=1; else IS_TTY=0; fi
          RED=$(if [ "$IS_TTY" = 1 ]; then ${pkgs.ncurses}/bin/tput setaf 1; fi)
          GREEN=$(if [ "$IS_TTY" = 1 ]; then ${pkgs.ncurses}/bin/tput setaf 2; fi)
          RESET=$(if [ "$IS_TTY" = 1 ]; then ${pkgs.ncurses}/bin/tput sgr0; fi)

          function waitforhosts() {
            local fail
            local host
            local _retry

            for _retry in {0..120}; do
              fail=0
              # shellcheck disable=SC2043
              for host in ${lib.strings.concatStringsSep " " (lib.lists.unique hosts)}; do
                ${pkgs.iputils}/bin/ping -c1 "$host" >/dev/null || fail=1
              done
              if [ "$fail" == "0" ]; then
                return 0
              fi
              sleep 1
            done
            echo "''${RED}Timeout waiting for network access to hosts''${RESET}"
            return 1
          }

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

          waitforhosts

          ${if jobcfg.preHooks != [] then ''echo "''${GREEN}Running backup prehooks...''${RESET}"'' else ""}
          ${pre-cmd}

          echo "''${GREEN}Copy files to remote...''${RESET}"
          ${lib.strings.concatStringsSep "\n\n" rsync-cmds}

          ${pkgs.coreutils}/bin/mkdir -p "${state-dir}"
          ${pkgs.coreutils}/bin/date +%s > "${state-dir}/${name}"
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
  check-backup-times = pkgs.writeShellApplication {
      name = "rsync-check-backup-times.sh";
      text =
        let
          checks = builtins.map (job: ''
            LAST_TIME_S=$(${pkgs.coreutils}/bin/cat "${state-dir}/${job.jobname}")
            TIME_SINCE_S=$(( NOW_S - LAST_TIME_S ))
            TIME_SINCE_H=$(( TIME_SINCE_S / 3600 ))
            if (( TIME_SINCE_H < ${toString max-backup-age} )); then
              echo "''${GREEN}OK - Backup for ${job.jobname} was executed ''${TIME_SINCE_H} hours ago ''${RESET}"
            else
              echo "''${RED}FAILED - Backup for ${job.jobname} was executed ''${TIME_SINCE_H} hours ago ''${RESET}"
              RESULT=1
            fi
          '') backup-jobs;
        in
          ''
            set +e errexit

            if [ -t 1 ]; then IS_TTY=1; else IS_TTY=0; fi
            RED=$(if [ "$IS_TTY" = 1 ]; then ${pkgs.ncurses}/bin/tput setaf 1; fi)
            GREEN=$(if [ "$IS_TTY" = 1 ]; then ${pkgs.ncurses}/bin/tput setaf 2; fi)
            RESET=$(if [ "$IS_TTY" = 1 ]; then ${pkgs.ncurses}/bin/tput sgr0; fi)
            NOW_S=$(date +%s)
            RESULT=0

            ${lib.strings.concatStringsSep "\n\n" checks}

            exit ''${RESULT}
          '';
  };
  has-backup-jobs = backup-jobs != [];
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

  config.environment.systemPackages = lib.mkIf (cfg.enable && has-backup-jobs)
    ((builtins.map (job: job.app) backup-jobs) ++ [
      backup-all-app
      check-backup-times
    ]);

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
          script = job.binpath;
        };
        # Älä aja varmuuskopiointia nixos-rebuild:n jälkeen, tee se vain
        # ajastettuna ajankohtana:
        #   https://discourse.nixos.org/t/how-to-prevent-custom-systemd-service-from-restarting-on-nixos-rebuild-switch/43431/3
        restartIfChanged = false;
        serviceConfig.RemainAfterExit = true;
      };
    }) backup-jobs);
    timers = builtins.listToAttrs (builtins.map (job: {
      name = "rsync-backup-${job.jobname}";
      value = {
        # Älä käynnistä varmuuskopiointia ennen kuin verkko on ylhäällä, tämä
        # tarvitaan `Persistent` asetuksen takia. Huomaa, että tämä ei vielä
        # riitä, sillä ainakaan dns-selvitys ei näytä vielä toimivan heti
        # verkon noustua ylös. Tätä varten skriptissä on `waitforhosts` funktio.
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        # Käynnistä backup koneen käynnistyksen jälkeen jos kone oli pois päältä
        # edellisen suoritusajan hetkellä
        timerConfig.Persistent = "true";
      };
    }) backup-jobs);
  };

  # Palveluiden valvonta
  config.my.services.monitoring = lib.mkIf cfg.enable {
    checks = (builtins.map (job:
      {
        type = "systemd service";
        description = "Backups - Job: ${job.jobname}";
        name = "rsync-backup-${job.jobname}.service";
        expected = "succeeded";
      }
    ) backup-jobs) ++ (if has-backup-jobs then [
      {
        type = "program";
        description = "Backups - Check backups are fresh";
        path = "${check-backup-times}/bin/rsync-check-backup-times.sh";
      }
    ] else []);
  };
}
