# ===========================
# Lokin seuraaminen:
#   journalctl -ft Nextcloud
# ===========================

{ lib, self, ... }:
{
  flake.modules.nixos.nextcloud = { config, pkgs, ... }: let
    inherit (self) catalog;

    nextcloudPackage = pkgs.nextcloud31;
    backupDbPath = "${config.services.nextcloud.datadir}/nextcloud-mariadb.backup";
    adminPassFile = pkgs.writeText "nextcloud-initialadminpass" "initial-pass";
    backupPrepare = pkgs.writeShellApplication {
      name = "nextcloud-backup-pre";
      runtimeInputs = [
        backupCleanup
        config.services.mysql.package
        config.services.nextcloud.occ
      ];
      text = ''
        set -e
        if [[ "$USER" != "root" ]]; then
          echo "This script must be run as root user" >&2;
          exit 1;
        fi
        echo "Preparing Nextcloud backup"
        nextcloud-occ maintenance:mode --on
        trap nextcloud-backup-post ERR
        echo "Dump database to ${backupDbPath}"
        mysqldump -u root --single-transaction \
          ${config.services.nextcloud.config.dbname} > "${backupDbPath}"
      '';
    };
    backupCleanup = pkgs.writeShellApplication {
      name = "nextcloud-backup-post";
      runtimeInputs = [
        pkgs.coreutils
        config.services.nextcloud.occ
      ];
      text = ''
        if [[ "$USER" != "root" ]]; then
          echo "This script must be run as root user" >&2;
          exit 1;
        fi
        nextcloud-occ maintenance:mode --off
        echo "Remove database dump ${backupDbPath}"
        rm -f "${backupDbPath}"
      '';
    };
    generateThumbnails = pkgs.writeShellApplication {
      name = "nextcloud-generate-thumbnails";
      runtimeInputs = [
        config.services.nextcloud.occ
      ];
      text = "nextcloud-occ preview:pre-generate";
    };
  in {
    services = {
      nextcloud = {
        enable = true;
        package = nextcloudPackage;
        hostName = catalog.services.nextcloud.public.domain;
        https = true;
        config = {
          adminuser = "valvoja";
          adminpassFile = "${adminPassFile}";
          dbhost = "localhost:/run/mysqld/mysqld.sock";
          dbtype = "mysql";
        };
        # Käytä Redisiä parammin toimivaan tiedostojen lukintaan:
        #   https://help.nextcloud.com/t/file-is-locked-how-to-unlock/1883
        configureRedis = true;
        maxUploadSize = "10G";
        # SMB External Storage: Asenna smbclient kirjasto
        phpExtraExtensions = all: [ all.smbclient ];
        phpOptions = {
          # Asetusten yleiskuvaus valittaa että strings puskuri on täynnä, tämä
          # nostaa rajaa ylemmäs
          "opcache.interned_strings_buffer" = "16";
        };

        # Nämä asetukset tulee config.php tiedostoon
        settings = {
          "log.condition".apps = [ "admin_audit" ]; # audit lokitus riippumatta lokitasosta
          default_phone_region = "FI";
          log_type_audit = "syslog";
          logfile_audit = "";
          #loglevel = 1; # Lokitaso, oletus on 2 (WARNING)
          maintenance_window_start = 23; # Klo 23 - 03 UTC aikaa
          overwriteprotocol = "https";
          syslog_tag = "Nextcloud";
          syslog_tag_audit = "Nextcloud";
          trusted_proxies = [ catalog.nodes.tunneli.ip.tailscale ];
        };
      };

      mysql = {
        enable = true;
        package = pkgs.mariadb;
        ensureDatabases = [ config.services.nextcloud.config.dbname ];
        ensureUsers = [{
          name = config.services.nextcloud.config.dbuser;
          ensurePermissions = {
            "${config.services.nextcloud.config.dbname}.*" = "ALL PRIVILEGES";
          };
        }];
      };

      # Tarvitaan hakuun tiedostojen sisällöistä
      elasticsearch = {
        enable = true;
        plugins = [
          pkgs.elasticsearchPlugins.ingest-attachment
        ];
      };
    };

    environment.systemPackages = [
      backupPrepare
      backupCleanup
    ];

    # Generoi esikatselukuvat automaattisesti
    systemd.services."nextcloud-thumbnail-generate" = {
      script = lib.getExe generateThumbnails;
      startAt = "daily";
      serviceConfig = {
        User = "nextcloud";
        Group = "nextcloud";
      };
    };

    # Varmuuskopiointi
    my.services.rsync.jobs.nextcloud = {
      preHooks = [ "${backupPrepare}/bin/nextcloud-backup-pre" ];
      postHooks = [ "${backupCleanup}/bin/nextcloud-backup-post" ];
      paths = [ "${config.services.nextcloud.datadir}/" ];
      readWritePaths = [ config.services.nextcloud.datadir ];
      destinations = [
        "nas-normal"
        {
          destination = "nas-minimal";
          excludes = [
            "/data/phakonen/**"
            "/data/valvoja/**"
            "/data/jhakonen/files/Data/Eve V/**"
            "/data/jhakonen/files/Data/Ohjelmapaketit/**"
            "/data/jhakonen/files/Data/Sarjakuvat/**"
            "/data/jhakonen/files/Data/Pelit/**"
            "/data/jhakonen/files/Data/Kirjallisuus/**"
            "/data/jhakonen/files/Data/Ohjelmapaketit/**"
            "/data/jhakonen/files/Tyo/**"
            "/data/jhakonen/files/=Inbox=/**"
            "/data/jhakonen/files/Henkilokohtainen/Virtuaalikoneet/**"
            "/data/jhakonen/files/Henkilokohtainen/Projektit/Anarchy Online/**"
            "/data/jhakonen/files/Henkilokohtainen/Projektit/World_of_Tanks/**"
            "/data/**/files_trashbin/**"
          ];
        }
      ];
    };

    # Palvelun valvonta
    my.services.monitoring.checks = [
      {
        type = "systemd service";
        description = "Nextcloud - phpfpm";
        name = config.systemd.services.phpfpm-nextcloud.name;
      }
      {
        type = "systemd service";
        description = "Nextcloud - redis";
        name = config.systemd.services.redis-nextcloud.name;
      }
      {
        type = "systemd service";
        description = "Nextcloud - cron";
        name = config.systemd.services.nextcloud-cron.name;
        extraStates = [
          "LAST_RUN_OK"
          "NOT_RUN_YET"
        ];
      }
      {
        type = "systemd service";
        description = "Nextcloud - setup";
        name = config.systemd.services.nextcloud-setup.name;
        extraStates = [
          "LAST_RUN_OK"
          "NOT_RUN_YET"
        ];
      }
      {
        type = "systemd service";
        description = "Nextcloud - update db";
        name = config.systemd.services.nextcloud-update-db.name;
        extraStates = [
          "LAST_RUN_OK"
          "NOT_RUN_YET"
        ];
      }
      {
        type = "http check";
        description = "Nextcloud - web interface";
        secure = true;
        domain = config.services.nextcloud.hostName;
        path = "/login";
        response.code = 200;
        alertAfterSec = 15 * 60;
      }
    ];
  };

  flake.modules.nixos.nextcloud-tunnel = {
    services.nginx = {
      enable = true;
      virtualHosts."nextcloud.jhakonen.com" = {
        locations."/" = {
          proxyPass = "http://kanto.tailscale.jhakonen.com";
          proxyWebsockets = true;
          recommendedProxySettings = true;
        };
        # Käytä Let's Encrypt sertifikaattia
        addSSL = true;
        useACMEHost = "jhakonen.com";
      };
    };
  };
}
