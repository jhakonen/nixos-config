{ catalog, config, my-packages, pkgs, ... }:
let
  gatewayConfig = {
    mqtt = {
      host = catalog.services.mosquitto.public.domain;
      port = catalog.services.mosquitto.port;
      username = "koti";
      password = "$MQTT_PASSWORD";
      ca_cert = "/etc/ssl/certs/ca-bundle.crt";
      ca_verify = false;
      topic_prefix = "bt-mqtt-gateway";
      client_id = "bt-mqtt-gateway";
      availability_topic = "availability";
    };
    manager = {
      command_timeout = 30;
      sensor_config = {
        topic = "homeassistant";
        retain = true;
      };
      topic_subscription.update_all = {
        topic = "homeassistant/status";
        payload = "online";
      };
      workers.ruuvitag = {
        args = {
          devices = {
            sauna = "FB:F4:05:4A:70:70";
            makuuhuone = "E2:7D:43:DE:99:0C";
            ulkona = "D4:43:1D:F2:66:45";
          };
          topic_prefix = "ruuvitag";
          no_data_timeout = 600;
        };
      };
    };
  };
  configFile = (pkgs.formats.yaml {}).generate "bt-mqtt-gateway.yaml" gatewayConfig;
  dataDir = "/var/lib/bt-mqtt-gateway";
in
{
  # TODO myöhemmin: Luo käyttäjä jolla palvelua ajetaan, bluez-pohjainen
  # ruuvitagin toteutus vaatii käyttäjän jolla sudo oikeus suorittaa hci*
  # -työkaluja ilman salasanaa. Vaihda toteutus Bleak-kirjastoon, näin sudo
  # -vaatimuskin saattaa poistua

  age.secrets.bt-mqtt-gateway-environment.file = ../../secrets/bt-mqtt-gateway-environment.age;

  systemd.services.bt-mqtt-gateway = {
    description = "bt-mqtt-gateway palvelu";
    wantedBy = [ "multi-user.target" ];
    path = [
      pkgs.bluez  # Lisää hci* työkalut polulle
      pkgs.envsubst
    ];
    preStart = ''
      umask 077
      mkdir -p ${dataDir}
      envsubst -i "${configFile}" -o "${dataDir}/bt-mqtt-gateway.yaml"
      hciconfig hci0 down
      hciconfig hci0 up
      '';
    serviceConfig = {
      Environment = "CONFIG_FILE=${dataDir}/bt-mqtt-gateway.yaml";
      EnvironmentFile = [ config.age.secrets.bt-mqtt-gateway-environment.path ];
      ExecStart = "${my-packages.bt-mqtt-gateway}/bin/bt-mqtt-gateway";
      Restart = "always";
      RestartSec = "5s";
      LogExtraFields = "ROLE=bt-mqtt-gateway";
    };
  };
}
