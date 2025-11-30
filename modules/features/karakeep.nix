# Tuhoa meilisearchin tiedostot jos se valittaa että tietokannan versio on liian vanha:
#  - systemctl stop meilisearch.service
#  - rm -r /var/lib/meilisearch /var/lib/private/meilisearch
#  - systemctl start meilisearch.service
#  - https://karakeep.kanto.lan.jhakonen.com/admin/background_jobs --> "Reindex All Bookmarks"
{ lib, self, ... }:
let
  inherit (self) catalog;
in {
  flake.modules.nixos.karakeep = { config, pkgs, ... }: {
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
    #   Käynnistä: systemctl start restic-backups-karakeep.service
    #   Snapshotit: sudo restic-karakeep snapshots
    my.services.restic.backups.karakeep = {
      repository = "rclone:nas:/backups/restic/karakeep";
      paths = [ "/var/lib/karakeep" ];
      backupPrepareCommand = "systemctl stop karakeep-browser.service karakeep-init.service karakeep-web.service karakeep-workers.service";
      backupCleanupCommand = "systemctl start karakeep-browser.service karakeep-init.service karakeep-web.service karakeep-workers.service";
      checkOpts = [ "--read-data" ];
      pruneOpts = [ "--keep-daily 7" "--keep-weekly 4" "--keep-monthly 12" ];
    };

    # Palvelun valvonta
    my.services.monitoring.checks = [
      {
        type = "systemd service";
        description = "karakeep - service";
        name = "karakeep-web.service";
      }
      {
        type = "http check";
        description = "karakeep - web interface";
        domain = catalog.services.karakeep.public.domain;
        path = "/signin";
        secure = true;
        response.code = 200;
        alertAfterSec = 15 * 60;
      }
    ];
  };

  flake.modules.nixos.gatus = {
    # Palvelun valvonta
    services.gatus.settings.endpoints = [{
      name = "Karakeep";
      url = "https://${catalog.services.karakeep.public.domain}";
      conditions = [ "[STATUS] == 200" ];
    }];
  };
}
