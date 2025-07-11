{ self, ... }:
{
  flake.modules.nixos.zigbee2mqtt = { config, ... }: let
    inherit (self) catalog;
    acmeHost = "${config.networking.hostName}.lan.jhakonen.com";
  in {
    services.zigbee2mqtt = {
      enable = true;
      settings = {
        homeassistant = true;
        permit_join = false;
        serial.port = "/dev/ttyUSB0";
        mqtt = {
          base_topic = "zigbee2mqtt";
          server = "mqtts://mqtt.jhakonen.com";
          user = "koti";
          reject_unauthorized = true;
        };
        advanced.report = true;
        ota.disable_automatic_update_check = true;
        devices = {
          "0x14b457fffe7e06cc" = {
            friendly_name = "tradfri-lamppu-1";
            description = "Olohuoneen kattovalaisimen lamppu";
          };
          "0x14b457fffe7e05ed" = {
            friendly_name = "tradfri-lamppu-2";
            description = "Olohuoneen kattovalaisimen lamppu";
          };
          "0xccccccfffe3c78b1" = {
            friendly_name = "tradfri-lamppu-3";
            description = "Olohuoneen kattovalaisimen lamppu";
          };
          "0x001788010d9f259a" = {
            friendly_name = "hue-lamppu-1";
            description = "Käytävän kattovalaisimen lamppu";
          };
          "0x001788010d9f2604" = {
            friendly_name = "hue-lamppu-2";
            description = "Käytävän kattovalaisimen lamppu";
          };
          "0x001788010d9f21f4" = {
            friendly_name = "hue-lamppu-3";
            description = "Käytävän kattovalaisimen lamppu";
          };
          "0x001788010d9f2624" = {
            friendly_name = "hue-lamppu-4";
            description = "Käytävän kattovalaisimen lamppu";
          };
          "0x001788010cfb6125" = {
            friendly_name = "hue-lamppu-5";
            description = "Tietokonepöydän lattiavalaisimen lamppu rgb 470lm";
          };
          "0x001788010cfe1265" = {
            friendly_name = "hue-lamppu-6";
            description = "Tietokonepöydän lattiavalaisimen lamppu rgb 470lm";
          };
          "0x001788010b9a83ea" = {
            friendly_name = "hue-lamppu-7";
            description = "Tietokonepöydän lattiavalaisimen lamppu rgb 800lm";
          };
          "0x086bd7fffe5a78ee" = {
            friendly_name = "pistoke-1";
            description = "Ei ohjaa mitään, toimii zigbee verkon extenderinä";
          };
          "0xf0d1b8000015dde5" = {
            friendly_name = "pistoke-2";
            description = "Tietokonepöydän sähköpistorasia";
          };
          "0x00158d00027a6155" = {
            friendly_name = "painike-1";
            description = "Tietokonepöydän sähköjen ohjauspainike";
          };
          "0x001788010d7daa37" = {
            friendly_name = "painike-2";
            description = "Olohuoneen valaisimen ohjain";
          };
        };
        groups = {};
        frontend.port = catalog.services.zigbee2mqtt.port;
      };
    };

    services.nginx = {
      enable = true;
      virtualHosts.${catalog.services.zigbee2mqtt.public.domain} = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString catalog.services.zigbee2mqtt.port}";
          proxyWebsockets = true;
          recommendedProxySettings = true;
        };
        # Käytä Let's Encrypt sertifikaattia
        addSSL = true;
        useACMEHost = acmeHost;
      };
    };

    security.acme.certs.${acmeHost}.extraDomainNames = [
      catalog.services.zigbee2mqtt.public.domain
    ];

    # Lisää MQTT salasana salatun ympäristömuuttujan kautta
    age.secrets.zigbee2mqtt-environment.file = ../../agenix/zigbee2mqtt-environment.age;
    systemd.services.zigbee2mqtt.serviceConfig.EnvironmentFile = [
      config.age.secrets.zigbee2mqtt-environment.path
    ];

    # Avaa palomuuriin hallintapaneelille reikä
    networking.firewall.allowedTCPPorts = [ catalog.services.zigbee2mqtt.port ];

    # Varmuuskopiointi
    my.services.rsync.jobs.zigbee2mqtt = {
      destinations = [
        "nas-normal"
        "nas-minimal"
      ];
      paths = [ "${config.services.zigbee2mqtt.dataDir}/" ];
      excludes = [ "${config.services.zigbee2mqtt.dataDir}/log" ];
    };

    # Palvelun valvonta
    my.services.monitoring.checks = [
      {
        type = "systemd service";
        description = "zigbee2mqtt - service";
        name = config.systemd.services.zigbee2mqtt.name;
      }
      {
        type = "http check";
        description = "zigbee2mqtt - web interface";
        domain = catalog.services.zigbee2mqtt.public.domain;
        secure = true;
        response.code = 200;
        alertAfterSec = 15 * 60;
      }
    ];
  };
}
