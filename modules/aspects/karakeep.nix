# Tuhoa meilisearchin tiedostot jos se valittaa että tietokannan versio on liian vanha:
#  - systemctl stop meilisearch.service
#  - rm -r /var/lib/meilisearch /var/lib/private/meilisearch
#  - systemctl start meilisearch.service
#  - https://karakeep.kanto.lan.jhakonen.com/admin/background_jobs --> "Reindex All Bookmarks"
{ config, ... }:
let
  inherit (config) catalog;
in {
  den.aspects.kanto.nixos = { config, ... }: {
    age.secrets.karakeep-environment.file = ../../agenix/karakeep-environment.age;

    services.karakeep = {
      enable = true;
      extraEnvironment = {
        DISABLE_SIGNUPS = "true";
        OCR_LANGS = "fin,eng";
        PORT = toString catalog.services.karakeep.port;
      };
      # Sisältää muuttujat NEXTAUTH_SECRET ja OPENAI_API_KEY
      environmentFile = config.age.secrets.karakeep-environment.path;
    };

    # Paljasta Karakeep karakeep.kanto.lan.jhakonen.com domainissa
    services.nginx = {
      enable = true;
      virtualHosts.${catalog.services.karakeep.public.domain} = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString catalog.services.karakeep.port}";
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
    #     systemctl start restic-backups-karakeep-oma.service
    #     systemctl start restic-backups-karakeep-veli.service
    #   Snapshotit:
    #     sudo restic-karakeep-oma snapshots
    #     sudo restic-karakeep-veli snapshots
    my.services.restic.backups = let
      bConfig = {
        paths = [ "/var/lib/karakeep" ];
        backupPrepareCommand = "systemctl stop karakeep-browser.service karakeep-init.service karakeep-web.service karakeep-workers.service";
        backupCleanupCommand = "systemctl start karakeep-browser.service karakeep-init.service karakeep-web.service karakeep-workers.service";
      };
    in {
      karakeep-oma = bConfig // {
        repository = "rclone:nas-oma:/backups/restic/karakeep";
        timerConfig.OnCalendar = "01:00";
      };
      karakeep-veli = bConfig // {
        repository = "rclone:nas-veli:/home/restic/karakeep";
        timerConfig.OnCalendar = "Sat 02:00";
      };
    };

    # Palvelun valvonta
    services.gatus.settings.endpoints = [{
      name = "Karakeep";
      url = "https://${catalog.services.karakeep.public.domain}";
      conditions = [ "[STATUS] == 200" ];
    }];
  };
}
