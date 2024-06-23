{ config, ... }:
let
  inherit (config.dep-inject) catalog private;
  user = "koti";
  certDir = config.security.acme.certs."jhakonen.com".directory;
in {
  # Salaisuudet
  age.secrets = {
    mosquitto-password = {
      file = private.secret-files.mqtt-password;
      owner = "mosquitto";
      group = "mosquitto";
    };
  };

  services.mosquitto = {
    enable = true;
    listeners = [
      {
        port = catalog.services.mosquitto.port;
        settings = {
          keyfile = "${certDir}/key.pem";
          certfile = "${certDir}/cert.pem";
          cafile = "${certDir}/chain.pem";
        };
        users = {
          "${user}" = {
            acl = [ "#" ];
            passwordFile = config.age.secrets.mosquitto-password.path;
          };
          # Käyttäjä yhteyden tarkistukseen monit-palvelusta
          testi = {
            acl = [ "deny #" ];
            password = "testi";
          };
        };
      }
    ];
  };

  # Lataa mosquitto uudelleen päivittäin jotta se lataa let's encryptin uudet
  # sertifikaattitiedostot kun ne muuttuvat
  systemd.services."mosquitto-letsencrypt-renew" = {
    script = "systemctl reload mosquitto.service";
    startAt = "daily";
  };

  networking.firewall.allowedTCPPorts = [ catalog.services.mosquitto.port ];

  # Lisää rooli lokiriveihin jotka Promtail lukee
  systemd.services.mosquitto.serviceConfig.LogExtraFields = "ROLE=mosquitto";

  # Anna mosquittolle pääsy let's encrypt sertifikaattiin
  users.groups.acme.members = [ "mosquitto" ];

  # Palvelun valvonta
  my.services.monitoring.checks = [
    {
      type = "systemd service";
      description = "Mosquitto - service";
      name = config.systemd.services.mosquitto.name;
      expected = "running";
    }
    ({ notify, ... }:
    ''
      check host "Mosquitto - MQTT connection" with address ${catalog.services.mosquitto.public.domain}
        if failed
          port ${toString catalog.services.mosquitto.port}
          ssl
          protocol mqtt username testi password testi
        then
          exec "${notify} ${config.networking.hostName} - check Mosquitto - MQTT connection has failed"
    '')
  ];
}
