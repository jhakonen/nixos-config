{ catalog, config, ... }:
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
          retain = true;
        };
        "0x14b457fffe7e05ed" = {
          friendly_name = "tradfri-lamppu-2";
          retain = true;
        };
        "0xf0d1b8000015dde5" = {
          friendly_name = "pistoke-2";
          description = "Osramin Ledvance pistoke";
        };
        "0x14b457fffe779423" = {
          friendly_name = "tradfri-ohjain-1";
        };
        "0xccccccfffe3c78b1" = {
          friendly_name = "tradfri-lamppu-3";
        };
        "0x086bd7fffe5a78ee" = {
          friendly_name = "pistoke-1";
        };
        "0x00158d00027a6155" = {
          friendly_name = "nappi1";
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

  # TODO: Lisää varmuuskopiointi
}
