{ lib, pkgs, config, ... }:
let
  cfg = config.roles.telegraf;
in {
  options.roles.telegraf = {
    enable = lib.mkEnableOption "Telegraf rooli";
    environmentFiles = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [];
    };
  };

  config = lib.mkIf cfg.enable {
    services.telegraf = {
      enable = true;
      environmentFiles = cfg.environmentFiles;
      extraConfig = {
        # Kerää ruuvitagien mittausdataa MQTT:stä
        inputs.mqtt_consumer = {
          servers = [ "ssl://mqtt.jhakonen.com:8883" ];
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
          urls = [ "http://localhost:8086" ];
          database = "telegraf";
        };
      };
    };
  };
}
