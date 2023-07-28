{ lib, pkgs, config, ... }:
let
  cfg = config.roles.mqttwarn;
in {
  options.roles.mqttwarn = {
    enable = lib.mkEnableOption "Mqttwarn rooli";
  };

  config = lib.mkIf cfg.enable {
    age.secrets.environment-variables.file = ../../secrets/environment-variables.age;

    services.mqttwarn = {
      enable = true;
      environmentFiles = [ config.age.secrets.environment-variables.path ];
      settings = {
        defaults = {
          hostname = "mqtt.jhakonen.com";
          port = 8883;
          username = "koti";
          password = "$ENV:MQTT_PASSWORD";
          clientid = "nas-toolbox-mqttwarn";
          tls = true;
          tls_version = "tlsv1_2";
          tls_insecure = false;
          launch = "telegram, smtp";
        };
        "config:telegram" = {
          timeout = 60;
          parse_mode = "Markdown";
          token = "$ENV:TELEGRAM_TOKEN";
          use_chat_id = true;
          targets.jhakonen = [ "$ENV:TELEGRAM_CHAT_ID" ];
        };
        "config:smtp" = {
          server = "***REMOVED***:587";
          sender = "$ENV:SMTP_FROM";
          username = "$ENV:SMTP_USERNAME";
          password = "$ENV:SMTP_PASSWORD";
          starttls = true;
          htmlmsg = false;
          targets.jhakonen = [ "$ENV:SMTP_TO" ];
        };
        "topic-telegram" = {
          topic = "mqttwarn/telegram";
          targets = "telegram:jhakonen";
        };
        "topic-smtp" = {
          topic = "mqttwarn/smtp";
          targets = "smtp:jhakonen";
          title = "{otsikko}";
          format = "{viesti}";
        };
      };
    };
  };
}