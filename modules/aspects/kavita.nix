{ inputs, ... }:
{
  den.aspects.kanto.nixos = { config, ... }: {

    # Kavitan asetukset
    services.kavita = {
      enable = true;
      settings.Port = config.catalog.services.kavita.port;
      tokenKeyFile = config.age.secrets.kavita-tokenkey.path;
    };

    # Salaisuudet
    age.secrets.kavita-tokenkey.file = ../../agenix/kavita-tokenkey.age;

    # Reverse proxyn asetukset
    services.nginx = {
      enable = true;
      virtualHosts.${config.catalog.services.kavita.public.domain} = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.catalog.services.kavita.port}";
          proxyWebsockets = true;
          recommendedProxySettings = true;
        };
        # Käytä Let's Encrypt sertifikaattia
        addSSL = true;
        useACMEHost = "jhakonen.com";
      };
    };

    # Varmuuskopiointi
    #   Käynnistä:
    #     systemctl start restic-backups-kavita-oma.service
    #     systemctl start restic-backups-kavita-veli.service
    #   Snapshotit:
    #     sudo restic-kavita-oma snapshots
    #     sudo restic-kavita-veli snapshots
    my.services.restic.backups = let
      bConfig = {
        paths = [ config.services.kavita.dataDir ];
        backupPrepareCommand = "systemctl stop podman-kavita.service";
        backupCleanupCommand = "systemctl start podman-kavita.service";
      };
    in {
      kavita-oma = bConfig // {
        repository = "rclone:nas-oma:/backups/restic/kavita";
        timerConfig.OnCalendar = "01:00";
      };
      kavita-veli = bConfig // {
        repository = "rclone:nas-veli:/home/restic/kavita";
        timerConfig.OnCalendar = "Sat 02:00";
        # Rajaa tarkistetun datan määrää koska backupissa menee 3+ tuntia
        # täydellä tarkistuksella, ja aiheuttaa yhteyden katkeamisen
        checkOpts = [ "--read-data-subset" "10%" ];
      };
    };

    # Palvelun valvonta
    services.gatus.settings.endpoints = [{
      name = "Kavita";
      url = "https://${config.catalog.services.kavita.public.domain}";
      conditions = [ "[STATUS] == 200" ];
    }];
  };
}