{ config, catalog, ... }:
let
  user = "koti";
  certDir = config.security.acme.certs."jhakonen.com".directory;
in {
  # Salaisuudet
  age.secrets = {
    mosquitto-password = {
      file = ../../secrets/mqtt-password.age;
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
        users."${user}" = {
          acl = [ "#" ];
          passwordFile = config.age.secrets.mosquitto-password.path;
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
}
