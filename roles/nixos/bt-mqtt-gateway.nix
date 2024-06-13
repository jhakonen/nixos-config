{ config, pkgs, ... }:
let
  catalog = config.dep-inject.catalog;
  my-packages = config.dep-inject.my-packages;

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
      pkgs.coreutils  # head
      pkgs.envsubst
      pkgs.gnugrep
    ];
    preStart = ''
      umask 077
      mkdir -p ${dataDir}
      envsubst -i "${configFile}" -o "${dataDir}/bt-mqtt-gateway.yaml"

      # "Korjaa" virhe: Bluetooth interface has gone down
      DEV_NAME=$(hcitool dev | grep -o 'hci[0-9]' | head -n1)
      hciconfig $DEV_NAME down
      hciconfig $DEV_NAME up
      '';
    serviceConfig = {
      Environment = "CONFIG_FILE=${dataDir}/bt-mqtt-gateway.yaml";
      EnvironmentFile = [ config.age.secrets.bt-mqtt-gateway-environment.path ];
      ExecStart = "${my-packages.bt-mqtt-gateway}/bin/bt-mqtt-gateway";
      Restart = "always";
      RestartSec = "30";
      LogExtraFields = "ROLE=bt-mqtt-gateway";
    };
    unitConfig = {
      # Käynnistä palvelu kun "Bluetooth interface has gone down" virhe tapahtuu, mutta rajoita
      # kuinka monta kertaa uudelleen käynnistys saa tapahtua jotta monitorointi havaitsee ongelman
      StartLimitIntervalSec = "200";
      StartLimitBurst = "5";
    };
  };

  my.services.monitoring.checks = [{
    type = "systemd service";
    description = "bt-mqtt-gateway";
    name = config.systemd.services.bt-mqtt-gateway.name;
    expected = "running";
  }];
}
