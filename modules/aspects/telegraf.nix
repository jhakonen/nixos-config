{
  den.aspects.kanto.nixos = { config, ... }: {
    age.secrets.telegraf-environment.file = ../../agenix/telegraf-environment.age;

    services.telegraf = {
      enable = true;
      environmentFiles = [ config.age.secrets.telegraf-environment.path ];
      extraConfig = {
        # Kerää ruuvitagien mittausdataa MQTT:stä
        inputs.mqtt_consumer = {
          servers = [ "ssl://${config.catalog.services.mosquitto.public.domain}:${toString config.catalog.services.mosquitto.port}" ];
          topics = [
            "bt-mqtt-gateway/ruuvitag/+/battery"
            "bt-mqtt-gateway/ruuvitag/+/humidity"
            "bt-mqtt-gateway/ruuvitag/+/pressure"
            "bt-mqtt-gateway/ruuvitag/+/temperature"
          ];
          topic_tag = "topic";
          client_id = "${config.networking.hostName}-telegraf";
          username = "koti";
          password = "$MQTT_PASSWORD";
          data_format = "value";
          data_type = "float";
          name_override = "ruuvitag";
        };

        # Tallenna kerätty data influxdb kantaan
        outputs.influxdb = {
          urls = [ "http://localhost:${toString config.catalog.services.influx-db.port}" ];
          database = "telegraf";
        };
      };
    };
  };
}
