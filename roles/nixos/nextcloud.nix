{ catalog, config, lib, pkgs, ... }:
let
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
in
{
  services = {
    nextcloud = {
      enable = true;
      package = pkgs.nextcloud25;
      hostName = catalog.services.nextcloud.public.domain;
      config = {
        adminuser = "valvoja";
        adminpassFile = "${adminPassFile}";
        dbhost = "localhost:/run/mysqld/mysqld.sock";
        dbtype = "mysql";
        overwriteProtocol = "https";
      };
    };

    nginx.virtualHosts.${config.services.nextcloud.hostName} = {
      listen = [{
        addr = "0.0.0.0";
        port = catalog.services.nextcloud.port;
        ssl = true;
      }];

      addSSL = true;
      # TODO: Korvaa Let's Encrypt sertifikaatilla
      sslCertificate = "/etc/wildcard-jhakonen-com.cert";
      sslCertificateKey = config.age.secrets.nextcloud-ssl-key-file.path;
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

    backup = {
      preHooks = [ "${backupPrepare}/bin/nextcloud-backup-pre" ];
      postHooks = [ "${backupCleanup}/bin/nextcloud-backup-post" ];
      paths = [ config.services.nextcloud.datadir ];
      readWritePaths = [ config.services.nextcloud.datadir ];
    };
  };

  age.secrets = {
    nextcloud-ssl-key-file = {
      file = ../../secrets/wildcard-jhakonen-com.key.age;
      owner = "nginx";
      group = "nginx";
    };
  };

  environment.systemPackages = [
    backupPrepare
    backupCleanup
  ];

  # Avaa palomuuriin palvelulle reikä
  networking.firewall.allowedTCPPorts = [ catalog.services.nextcloud.port ];

  users = lib.mkIf config.services.nextcloud.enable {
    # Nämä ID arvot tulee olla samat kuin Synologyssä
    users.nextcloud.uid = 1032;
    groups.nextcloud.gid = 65538;
  };

  # Liitä Netcloudin datakansio NFS:n yli NAS:lta
  fileSystems.${config.services.nextcloud.datadir} = {
    device = "${catalog.nodes.nas.ip.private}:/volume1/nextcloud";
    fsType = "nfs";
    options = [
      "noauto"
      "x-systemd.automount"
      "x-systemd.after=network-online.target"
      "x-systemd.mount-timeout=90"
    ];
  };
}
