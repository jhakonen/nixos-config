# Käyttäjä ja salasana on luotu komennolla:
#   sudo htpasswd -5 -c /var/lib/radicale/users jhakonen

{ self, ... }:
let
  inherit (self) catalog;
in
{
  flake.modules.nixos.radicale = { config, pkgs, ... }: {
    services.radicale = {
      enable = true;
      settings = {
        server.hosts = [ "127.0.0.1:${toString catalog.services.radicale.port}" ];
        auth = {
          type = "htpasswd";
          htpasswd_filename = "/var/lib/radicale/users";
          htpasswd_encryption = "sha512";
        };
        storage.filesystem_folder = "/var/lib/radicale/collections";
      };
    };

    environment.systemPackages = with pkgs; [
      apacheHttpd
    ];

    services.nginx = {
      enable = true;
      virtualHosts.${catalog.services.radicale.public.domain} = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString catalog.services.radicale.port}";
          recommendedProxySettings = true;
        };
        extraConfig = ''
          proxy_pass_header Authorization;
        '';
        # Käytä Let's Encrypt sertifikaattia
        addSSL = true;
        useACMEHost = "jhakonen.com";
      };
    };

    # Varmuuskopiointi
    #   Käynnistä: systemctl start restic-backups-radicale.service
    #   Snapshotit: sudo restic-radicale snapshots
    my.services.restic.backups.radicale = {
      repository = "rclone:nas:/backups/restic/radicale";
      paths = [ "/var/lib/radicale" ];
      backupPrepareCommand = "systemctl stop radicale.service";
      backupCleanupCommand = "systemctl start radicale.service";
      checkOpts = [ "--read-data" ];
      pruneOpts = [ "--keep-daily 7" "--keep-weekly 4" "--keep-monthly 12" ];
    };

    # Palvelun valvonta
    my.services.monitoring.checks = [
      {
        type = "http check";
        description = "Radicale - web interface";
        secure = true;
        path = "/.web/";
        domain = catalog.services.radicale.public.domain;
        response.code = 200;
      }
    ];
  };

}