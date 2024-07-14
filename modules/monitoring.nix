{ config, lib, pkgs, ... }:
let
  cfg = config.my.services.monitoring;
  MONIT_PORT = 2812;
  PERIOD = 60;
  DEFAULT_ALERT_AFTER_SEC = 5 * 60;

  secsToCycles = seconds: toString (seconds / PERIOD);

  buildConfig = check:
    if builtins.isString check then
      check
    else if check.type == "systemd service" then
      ''
        check program "${if check ? description then check.description else check.name}" with path "${checkSystemdService} ${check.name} ${check.expected}"
          if status != 0
            for ${secsToCycles DEFAULT_ALERT_AFTER_SEC} cycles
          then
            exec "${mqttAlertCmd} ${config.networking.hostName} - System service '${if check ? description then check.description else check.name}' has failed"
      ''
    else if check.type == "program" then
      ''
        check program "${check.description}" with path "${check.path}"
          if status != 0
            for ${secsToCycles DEFAULT_ALERT_AFTER_SEC} cycles
          then
            exec "${mqttAlertCmd} ${config.networking.hostName} - Check '${check.description}' has failed"
      ''
    else if check.type == "http check" then
      ''
        check host "${check.description}" with address ${check.domain}
          if failed
            port ${
              if check ? port then
                toString check.port
              else if check ? secure && check.secure then
                "443"
              else
                "80"
            }
            ${if check ? secure && check.secure then "certificate valid > 30 days" else ""}
            protocol ${if check ? secure && check.secure then "https" else "http"}
              ${if check ? path then "request ${check.path}" else ""}
              ${if check ? response.code then "status ${toString check.response.code}" else ""}
            for ${secsToCycles (if check ? alertAfterSec then check.alertAfterSec else DEFAULT_ALERT_AFTER_SEC)} cycles
          then
            exec "${mqttAlertCmd} ${config.networking.hostName} - HTTP check '${check.description}' has failed"
      ''
    else abort "Unknown check type for monioring: ${check.type}";


  checkSystemdService = pkgs.writeScript "check-systemd-service" ''
    #!/bin/sh
    LOGS=$(${pkgs.systemd}/bin/systemctl status "$1")
    if [ $? == 0 ]; then
      # Test service that has RemainAfterExit=true
      if $(echo "''${LOGS}" | ${pkgs.gnugrep}/bin/grep --quiet 'Active: active (exited)'); then
        echo "Last run ok"
      else
        echo "Running"
      fi
      echo "''${LOGS}"
      exit 0
    else
      if $(echo "''${LOGS}" | ${pkgs.gnugrep}/bin/grep --quiet 'Active: activating'); then
        echo "Starting up"
        echo "''${LOGS}"
        exit 0
      fi
      if [ "$2" == "running" ]; then
        echo "Stopped"
        echo "''${LOGS}"
        exit 1
      elif [ "$2" == "succeeded" ]; then
        if $(echo "''${LOGS}" | ${pkgs.gnugrep}/bin/grep --quiet 'Deactivated successfully'); then
          echo "Last run ok"
          echo "''${LOGS}"
          exit 0
        fi
        if $(echo "''${LOGS}" | ${pkgs.gnugrep}/bin/grep --quiet 'Active: inactive'); then
          echo "Not run yet"
          echo "''${LOGS}"
          exit 0
        fi
        echo "Last run failed"
        echo "''${LOGS}"
        exit 1
      else
        echo "Invalid expected state"
        exit 2
      fi
    fi
  '';

  mqttAlertCmd = pkgs.writeShellScript "mqtt-alert" ''
    echo "$@" | ${pkgs.mosquitto}/bin/mosquitto_pub \
      -h ${cfg.mqttAlert.address} \
      -p ${toString cfg.mqttAlert.port} \
      -u koti \
      -P $(${pkgs.coreutils}/bin/cat ${cfg.mqttAlert.passwordFile}) \
      -l \
      -t 'mqttwarn/telegram'
  '';

in {
  options.my.services.monitoring = {
    enable = lib.mkEnableOption "valvonta palvelu";
    checks = lib.mkOption {
      type = lib.types.listOf (lib.types.oneOf [
        lib.types.attrs
        lib.types.str
        lib.types.anything  # No type for function :(
      ]);
    };
    acmeHost = lib.mkOption {
      type = lib.types.str;
    };
    virtualHost = lib.mkOption {
      type = lib.types.str;
    };
    mqttAlert = lib.mkOption {
      type = (lib.types.submodule {
        options = {
          enable = lib.mkEnableOption "enable mqtt alerts";
          address = lib.mkOption {
            type = lib.types.str;
          };
          port = lib.mkOption {
            type = lib.types.int;
          };
          passwordFile = lib.mkOption {
            type = lib.types.str;
          };
        };
      });
    };
  };

  config.services.monit = lib.mkIf cfg.enable {
    enable = true;
    config = builtins.concatStringsSep "\n" (
      [''
        set daemon ${toString PERIOD}
        set limits { programoutput: 5 kB }
        set httpd port ${toString MONIT_PORT}
            allow localhost
      '']
      ++
      (builtins.map (check:
        buildConfig (
          if builtins.isFunction check then
            check {
              inherit checkSystemdService;
              inherit secsToCycles;
              notify = mqttAlertCmd;
            }
          else
            check
        )
      ) cfg.checks)
    );
  };

  config.services.nginx = lib.mkIf cfg.enable {
    enable = true;
    virtualHosts.${cfg.virtualHost} = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString MONIT_PORT}";
        recommendedProxySettings = true;
      };
      # Käytä Let's Encrypt sertifikaattia
      addSSL = true;
      useACMEHost = cfg.acmeHost;
    };
  };
}
