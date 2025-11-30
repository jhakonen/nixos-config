{ self, ... }: let
  inherit (self) catalog;
in {
  flake.modules.nixos.mqtt-server = { config, ... }: let
    user = "koti";
    certDir = config.security.acme.certs."jhakonen.com".directory;
  in {
    # Salaisuudet
    age.secrets = {
      mosquitto-password = {
        file = ../../agenix/mqtt-password.age;
        owner = "mosquitto";
        group = "mosquitto";
      };
    };

    services.mosquitto = {
      enable = true;
      listeners = [
        {
          port = catalog.services.mosquitto.insecure_port;
          # Käyttäjä esp32 laitteille koska ne eivät tue kryptattua MQTT:tä
          users.esphomeuser = {
            acl = [ "#" ];
            passwordFile = config.age.secrets.mosquitto-esphome-password.path;
          };
        }
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

    networking.firewall.allowedTCPPorts = [
      catalog.services.mosquitto.port
      catalog.services.mosquitto.insecure_port
    ];

    # Anna mosquittolle pääsy let's encrypt sertifikaattiin
    users.groups.acme.members = [ "mosquitto" ];

    # Palvelun valvonta
    my.services.monitoring.checks = [{
      type = "systemd service";
      description = "Mosquitto - service";
      name = config.systemd.services.mosquitto.name;
    }];
  };

  flake.modules.nixos.gatus = {
    # Palvelun valvonta
    services.gatus.settings.endpoints = [{
      name = "Mosquitto (secure)";
      url = "tcp://${catalog.services.mosquitto.public.domain}:${toString catalog.services.mosquitto.port}";
      conditions = [ "[CONNECTED] == true" ];
    } {
      name = "Mosquitto (insecure)";
      url = "tcp://${catalog.services.mosquitto.public.domain}:${toString catalog.services.mosquitto.insecure_port}";
      conditions = [ "[CONNECTED] == true" ];
    }];
  };
}
