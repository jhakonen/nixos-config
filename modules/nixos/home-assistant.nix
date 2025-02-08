{ config, flake, lib, pkgs, ... }:
let
  inherit (flake.lib) catalog;
in
{
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
  my.services.rsync.jobs.home-assistant = {
    destinations = [
      "nas-normal"
      "nas-minimal"
    ];
    paths = [ "${config.services.home-assistant.configDir}/" ];
    preHooks = [ "systemctl stop home-assistant.service" ];
    postHooks = [ "systemctl start home-assistant.service" ];
  };

  # Palvelun valvonta
  my.services.monitoring.checks = [
    {
      type = "systemd service";
      description = "Home Assistant - service";
      name = config.systemd.services.home-assistant.name;
    }
    {
      type = "http check";
      description = "Home Assistant - web interface";
      secure = true;
      domain = catalog.services.home-assistant.public.domain;
      response.code = 200;
    }
  ];
}
