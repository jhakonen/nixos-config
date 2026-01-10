# Skannerin FTP profiilin asetukset
#   - Host Address: kanto.lan.jhakonen.com
#   - Username: ftp
#   - Password: 123 (ei väliä, voi olla mitä vain)
#   - Store Directory: paperless-consume
# Loput oletuksilla.
#
{ self, ... }: let
  inherit (self) catalog;
in {
  flake.modules.nixos.paperless = { config, pkgs, ... }: let
    # Varmuuskopiokansio joka sisältää tietokannan ja dokumenttien exportin
    exportDir = "${config.services.paperless.dataDir}/exports";
  in {
    imports = [ self.modules.nixos.vsftpd ];

    services.paperless = {
      enable = true;
      settings = {
        # Formaatin muutoksen jälkeen aja komento: paperless-manage document_renamer
        PAPERLESS_FILENAME_FORMAT = "{{ created_year }}-{{ created_month }}-{{ created_day }} {{ title }}";
        PAPERLESS_OCR_LANGUAGE = "fin";
        PAPERLESS_OCR_LANGUAGES = "fin";
        # Tämä tarvitaan jotta Paperless ei estä pääsyä CSRF tarkistuksen takia
        PAPERLESS_URL = "${catalog.getServiceScheme catalog.services.paperless}://${catalog.getServiceAddress catalog.services.paperless}";
        # Sähköpostin skannaus-workeri meni jumiin ja söi 70% cputa, otetaan pois käytöstä
        PAPERLESS_EMAIL_TASK_CRON = "disable";
      };
      port = catalog.services.paperless.port;
      address = "0.0.0.0";  # Salli pääsy palveluun koneen ulkopuolelta (oletuksena 'localhost')

      # Syötekansio hakemistoon johon anonymous FTP käyttäjä pystyy kirjoittamaan
      consumptionDir = "${config.services.vsftpd.anonymousUserHome}/paperless-consume";
      consumptionDirIsPublic = true;
    };

    systemd.tmpfiles.settings.paperless = {
      # Anna jhakonen käyttäjälle lukuoikeus dokumentteihin
      "${config.services.paperless.mediaDir}/documents/archive" = {
        A.argument = "u:jhakonen:r-x,d:u:jhakonen:r--";
      };
    };

    services.nginx = {
      enable = true;
      virtualHosts.${catalog.services.paperless.public.domain} = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString catalog.services.paperless.port}";
          proxyWebsockets = true;
          recommendedProxySettings = true;
        };
        # Käytä Let's Encrypt sertifikaattia
        addSSL = true;
        useACMEHost = "jhakonen.com";
      };
    };

    # Avaa palomuuriin palvelulle reikä
    networking.firewall.allowedTCPPorts = [ catalog.services.paperless.public.port ];

    # Varmuuskopiointi
    #   Käynnistä:
    #     systemctl start restic-backups-paperless-oma.service
    #     systemctl start restic-backups-paperless-veli.service
    #   Snapshotit:
    #     sudo restic-paperless-oma snapshots
    #     sudo restic-paperless-veli snapshots
    my.services.restic.backups = let
      bConfig = {
        # Paperlessin tietokanta ja dokumentit
        paths = [ config.services.paperless.dataDir ];
        backupPrepareCommand = ''
          # Exporttaa varmuuskopio
          chown paperless:paperless ${exportDir}
          ${pkgs.util-linux}/bin/runuser -u paperless -- ${config.services.paperless.manage}/bin/paperless-manage document_exporter --delete --use-filename-format --use-folder-prefix ${exportDir}

          # Vedä alas paperlessin palvelut jotta tietokannan tiedostot voidaan
          # varmuuskopioida turvallisesti
          systemctl stop paperless-consumer.service paperless-scheduler.service paperless-task-queue.service paperless-web.service
        '';
        backupCleanupCommand = ''
          # Nosta palvelut takaisin ylös varmuuskopioinnin jälkeen
          systemctl start paperless-consumer.service paperless-scheduler.service paperless-task-queue.service paperless-web.service
        '';
      };
    in {
      paperless-oma = bConfig // {
        repository = "rclone:nas-oma:/backups/restic/paperless";
        timerConfig.OnCalendar = "01:00";
      };
      paperless-veli = bConfig // {
        repository = "rclone:nas-veli:/home/restic/paperless";
        timerConfig.OnCalendar = "Sat 02:00";
      };
    };

    # Palvelun valvonta
    my.services.monitoring.checks = [
      {
        type = "systemd service";
        description = "Paperless - consumer";
        name = config.systemd.services.paperless-consumer.name;
      }
      {
        type = "systemd service";
        description = "Paperless - scheduler";
        name = config.systemd.services.paperless-scheduler.name;
      }
      {
        type = "systemd service";
        description = "Paperless - task-queue";
        name = config.systemd.services.paperless-task-queue.name;
      }
      {
        type = "systemd service";
        description = "Paperless - web service";
        name = config.systemd.services.paperless-web.name;
      }
    ];
  };

  flake.modules.nixos.gatus = {
    # Palvelun valvonta
    services.gatus.settings.endpoints = [{
      name = "Paperless";
      url = "https://${catalog.services.paperless.public.domain}";
      conditions = [ "[STATUS] == 200" ];
    }];
  };
}
