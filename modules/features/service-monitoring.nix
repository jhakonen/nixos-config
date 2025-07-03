{ lib, ... }:
{
  flake.modules.nixos.service-monitoring = { config, pkgs, ... }: let
    cfg = config.my.services.monitoring;
    MONIT_PORT = 2812;
    PERIOD = 60;
    DEFAULT_ALERT_AFTER_SEC = 5 * 60;

    secsToCycles = seconds: toString (seconds / PERIOD);

    buildConfig = check:
      if builtins.isString check then
        check
      else if check.type == "systemd service" then
        let
          serviceCheck = "${checkSystemdService} ${check.name} ${builtins.concatStringsSep " " (if check ? extraStates then check.extraStates else [])}";
        in ''
          check program "${if check ? description then check.description else check.name}" with path "${serviceCheck}"
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


    # Arguments
    #  $1    - Systemd service name
    #  $2..n - List of extra ok states, choices: LAST_RUN_OK, NOT_RUN_YET
    checkSystemdService = pkgs.writeShellScript "check-systemd-service" ''
      SERVICE="$1"
      shift
      OK_STATES="$@"
      STATUS=$(${pkgs.systemd}/bin/systemctl status "$SERVICE")
      EXIT_CODE=0

      if [[ "$STATUS" =~ (Active: inactive \(dead\)) ]] && ! [[ "$STATUS" =~ (Main PID) ]] && [[ "$OK_STATES" =~ NOT_RUN_YET ]]; then
        echo "Not run yet"
      elif ([[ "$STATUS" =~ (Active: inactive \(dead\)) ]] || [[ "$STATUS" =~ (Active: active \(exited\)) ]]) \
           && [[ "$STATUS" =~ (Main PID: .+ status=0/SUCCESS) ]] \
           && [[ "$OK_STATES" =~ LAST_RUN_OK ]]; then
        echo "Last run ok"
      elif [[ "$STATUS" =~ (Active: active \(running\)) ]]; then
        echo "Running"
      elif [[ "$STATUS" =~ (Active: activating) ]]; then
        echo "Starting up"
        EXIT_CODE=1
      else
        echo "Failed"
        EXIT_CODE=1
      fi

      echo "$STATUS"
      exit $EXIT_CODE
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
  };
}
