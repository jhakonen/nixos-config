{ config, ... }:
let
  inherit (config.dep-inject) catalog private;
in
{
  age.secrets.mqttwarn-environment.file = private.secret-files.mqttwarn-environment;

  services.mqttwarn = {
    enable = true;
    environmentFiles = [ config.age.secrets.mqttwarn-environment.path ];
    settings = {
      defaults = {
        hostname = catalog.services.mosquitto.public.domain;
        port = catalog.services.mosquitto.port;
        username = "koti";
        password = "$ENV:MQTT_PASSWORD";
        clientid = "${config.networking.hostName}-mqttwarn";
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
        server = "posteo.de:587";
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

  # Palvelun valvonta
  my.services.monitoring.checks = [
    {
      type = "systemd service";
      description = "Mqttwarn - service";
      name = config.systemd.services.mqttwarn.name;
    }
  ];
}
