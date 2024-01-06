{ config, ... }:
let
  catalog = config.dep-inject.catalog;
in
{
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
        ca = "/etc/ssl/certs/ca-bundle.crt";
        reject_unauthorized = true;
      };
      advanced.report = true;
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

  # Lisää MQTT salasana salatun ympäristömuuttujan kautta
  age.secrets.zigbee2mqtt-environment.file = ../../secrets/zigbee2mqtt-environment.age;
  systemd.services.zigbee2mqtt.serviceConfig.EnvironmentFile = [
    config.age.secrets.zigbee2mqtt-environment.path
  ];

  # Lisää rooli lokiriveihin jotka Promtail lukee
  systemd.services.zigbee2mqtt.serviceConfig.LogExtraFields = "ROLE=zigbee2mqtt";

  # Avaa palomuuriin hallintapaneelille reikä
  networking.firewall.allowedTCPPorts = [ catalog.services.zigbee2mqtt.port ];

  # Varmuuskopiointi
  services.backup.paths = [ config.services.zigbee2mqtt.dataDir ];
  services.backup.excludes = [ "${config.services.zigbee2mqtt.dataDir}/log" ];
}
