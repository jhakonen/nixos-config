{ config, lib, pkgs, ... }:
let
  cfg = config.my.services.monitoring;
  MONIT_PORT = 2812;

  checkSystemdService = pkgs.writeScript "check-systemd-service" ''
    #!/bin/sh
    LOGS=$(${pkgs.systemd}/bin/systemctl status "$1")
    if [ $? == 0 ]; then
      echo "Running"
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
        echo "Last run failed"
        echo "''${LOGS}"
        exit 1
      else
        echo "Invalid expected state"
        exit 2
      fi
    fi
  '';

  parseHttpsCheck = config: let
    parts = builtins.match "([a-z]+)://([a-z.]+)(/.+)?" config.address;
  in {
    name = builtins.elemAt parts 1;
    address = builtins.elemAt parts 1;
    port = 443;
    protocol = builtins.elemAt parts 0;
    request = builtins.elemAt parts 2;
    status = config.response.code;
    content = config.response.body;
  };
in {
  options.my.services.monitoring = {
    enable = lib.mkEnableOption "valvonta palvelu";
    services = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
          };
          expected = lib.mkOption {
            type = lib.types.str;
            apply = x:
              if
                lib.lists.any (i: i == x) ["running" "succeeded"]
              then x
              else abort "expected ${x} must be one of [running, succeeded]";
          };
        };
      });
      default = [];
    };
    network = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          address = lib.mkOption {
            type = lib.types.str;
          };
          response = lib.mkOption {
            type = lib.types.submodule {
              options = {
                body = lib.mkOption {
                  type = lib.types.str;
                };
                code = lib.mkOption {
                  type = lib.types.int;
                };
              };
            };
          };
        };
      });
      default = [];
    };
    configs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
    };
    virtualHost = lib.mkOption {
      type = lib.types.str;
    };
  };

  config.services.monit = lib.mkIf cfg.enable {
    enable = true;
    config = builtins.concatStringsSep "\n" (
      [''
        set daemon 60
        set limits { programoutput: 5 kB }
        set httpd port ${toString MONIT_PORT}
            allow localhost
      '']
      ++
      (map (serviceCfg: ''
        check program ${serviceCfg.name} with path "${checkSystemdService} ${serviceCfg.name} ${serviceCfg.expected}"
          if status != 0 then alert
      '') cfg.services)
      ++
      (builtins.map (config: let
        vars = parseHttpsCheck config;
      in ''
        check host ${vars.name} with address ${vars.address}
          if failed
            port ${toString vars.port}
            certificate valid > 30 days
            protocol ${vars.protocol}
              request "${vars.request}"
              status ${toString vars.status}
              content = "${vars.content}"
          then alert
      '') cfg.network)
      ++
      cfg.configs
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
      useACMEHost = "jhakonen.com";
    };
  };
}
