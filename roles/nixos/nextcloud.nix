{ catalog, config, lib, pkgs, ... }:
let
  adminPassFile = pkgs.writeText "nextcloud-initialadminpass" "initial-pass";
in
{
  services.nextcloud = {
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

  services.nginx.virtualHosts.${config.services.nextcloud.hostName} = {
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

  age.secrets = {
    nextcloud-ssl-key-file = {
      file = ../../secrets/wildcard-jhakonen-com.key.age;
      owner = "nginx";
      group = "nginx";
    };
  };

  # Avaa palomuuriin palvelulle reikä
  networking.firewall.allowedTCPPorts = [ catalog.services.nextcloud.port ];

  services.mysql = {
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
