{ config, ... }:
let
  catalog = config.dep-inject.catalog;
in
{
  age.secrets.telegraf-environment.file = ../../secrets/telegraf-environment.age;

  services.telegraf = {
    enable = true;
    environmentFiles = [ config.age.secrets.telegraf-environment.path ];
    extraConfig = {
      # Kerää ruuvitagien mittausdataa MQTT:stä
      inputs.mqtt_consumer = {
        servers = [ "ssl://${catalog.services.mosquitto.public.domain}:${toString catalog.services.mosquitto.port}" ];
        topics = [
          "bt-mqtt-gateway/ruuvitag/+/battery"
          "bt-mqtt-gateway/ruuvitag/+/humidity"
          "bt-mqtt-gateway/ruuvitag/+/pressure"
          "bt-mqtt-gateway/ruuvitag/+/temperature"
        ];
        topic_tag = "topic";
        client_id = "telegraf-nas-toolbox";
        username = "koti";
        password = "$MQTT_PASSWORD";
        data_format = "value";
        data_type = "float";
        name_override = "ruuvitag";
      };

      # Tallenna kerätty data influxdb kantaan
      outputs.influxdb = {
        urls = [ "http://localhost:${toString catalog.services.influx-db.port}" ];
        database = "telegraf";
      };
    };
  };

  # Lisää rooli lokiriveihin jotka Promtail lukee
  systemd.services.telegraf.serviceConfig.LogExtraFields = "ROLE=telegraf";
}
