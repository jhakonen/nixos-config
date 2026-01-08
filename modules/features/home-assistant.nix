{ lib, self, ... }:
let
  inherit (self) catalog;
in
{
  flake.modules.nixos.home-assistant = { config, pkgs, ... }: {
    services.home-assistant = {
      enable = true;
      config = {
        automation = "!include automations.yaml";
        http = {
          server_port = catalog.services.home-assistant.port;
          use_x_forwarded_for = true;
          trusted_proxies = [
            "127.0.0.1"  # Luota nginx palveluun
          ];
        };
        homeassistant = {
          country = "FI";
          language = "en-GB";
          external_url = "https://${catalog.services.home-assistant.public.domain}";
          auth_providers = [
            {
              type = "trusted_networks";
              trusted_networks = [
                "10.0.0.0/24"  # lähiverkko
                "100.0.0.0/8"  # häntäverkko
              ];
              allow_bypass_login = true;
            }
            {
              type = "homeassistant";
            }
          ];
        };
        default_config = {};
      };
      extraComponents = [
        "androidtv_remote"
        "default_config"
        "esphome"
        "github"
        "met"
        "mqtt"
      ];
    };

    # Ota mDNS käyttöön jotta Esphome tunnistaa esp32-laiteen olevan online tilassa
    services.avahi.enable = true;

    services.esphome = {
      enable = true;
      port = catalog.services.esphome.port;
    };
    # https://github.com/NixOS/nixpkgs/issues/339557
    systemd.services.esphome = let
      cfg = config.services.esphome;
      stateDir = "/var/lib/private/esphome";
    in {
      environment.PLATFORMIO_CORE_DIR = lib.mkForce "/var/lib/private/esphome/.platformio";
      serviceConfig = {
        ExecStart = lib.mkForce "${cfg.package}/bin/esphome dashboard --address ${cfg.address} --port ${toString cfg.port} ${stateDir}";
        WorkingDirectory = lib.mkForce stateDir;
      };
    };

    environment.systemPackages = with pkgs; [
      esphome
    ];

    services.nginx = {
      enable = true;
      virtualHosts.${catalog.services.esphome.public.domain} = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString catalog.services.esphome.port}";
          proxyWebsockets = true;
          recommendedProxySettings = true;
        };
        # Käytä Let's Encrypt sertifikaattia
        addSSL = true;
        useACMEHost = "jhakonen.com";
      };
      virtualHosts.${catalog.services.home-assistant.public.domain} = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString catalog.services.home-assistant.port}";
          proxyWebsockets = true;
          recommendedProxySettings = true;
        };
        # Käytä Let's Encrypt sertifikaattia
        addSSL = true;
        useACMEHost = "jhakonen.com";
      };
    };

    # Puhkaise reikä palomuuriin
    networking.firewall.allowedTCPPorts = [ catalog.services.home-assistant.public.port ];

    # Varmuuskopiointi
    #   Käynnistä:
    #     systemctl start restic-backups-home-assistant-oma.service
    #     systemctl start restic-backups-home-assistant-veli.service
    #   Snapshotit:
    #     sudo restic-home-assistant-oma snapshots
    #     sudo restic-home-assistant-veli snapshots
    my.services.restic.backups = let
      bConfig = {
        paths = [
          config.services.home-assistant.configDir
          "/var/lib/private/esphome"
        ];
        backupPrepareCommand = "systemctl stop home-assistant.service";
        backupCleanupCommand = "systemctl start home-assistant.service";
      };
    in {
      home-assistant-oma = bConfig // {
        repository = "rclone:nas-oma:/backups/restic/home-assistant";
        timerConfig.OnCalendar = "01:00";
      };
      home-assistant-veli = bConfig // {
        repository = "rclone:nas-veli:/homes/janne/restic/home-assistant";
        timerConfig.OnCalendar = "02:00";
      };
    };

    # Palvelun valvonta
    my.services.monitoring.checks = [{
      type = "systemd service";
      description = "Home Assistant - service";
      name = config.systemd.services.home-assistant.name;
    }];
  };

  flake.modules.nixos.gatus = {
    # Palvelun valvonta
    services.gatus.settings.endpoints = [{
      name = "Home Assistant";
      url = "https://${catalog.services.home-assistant.public.domain}";
      conditions = [ "[STATUS] == 200" ];
    } {
      name = "Home Assistant (ESPHome)";
      url = "https://${catalog.services.esphome.public.domain}";
      conditions = [ "[STATUS] == 200" ];
    }];
  };
}
