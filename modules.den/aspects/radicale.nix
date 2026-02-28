# Käyttäjä ja salasana on luotu komennolla:
#   sudo htpasswd -5 -c /var/lib/radicale/users jhakonen

{ config, ... }:
let
  inherit (config) catalog;
in
{
  den.aspects.kanto.nixos = { config, pkgs, ... }: {
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
    #   Käynnistä:
    #     systemctl start restic-backups-radicale-oma.service
    #     systemctl start restic-backups-radicale-veli.service
    #   Snapshotit:
    #     sudo restic-radicale-oma snapshots
    #     sudo restic-radicale-veli snapshots
    my.services.restic.backups = let
      bConfig = {
        paths = [ "/var/lib/radicale" ];
        backupPrepareCommand = "systemctl stop radicale.service";
        backupCleanupCommand = "systemctl start radicale.service";
      };
    in {
      radicale-oma = bConfig // {
        repository = "rclone:nas-oma:/backups/restic/radicale";
        timerConfig.OnCalendar = "01:00";
      };
      radicale-veli = bConfig // {
        repository = "rclone:nas-veli:/home/restic/radicale";
        timerConfig.OnCalendar = "Sat 02:00";
      };
    };

    # Palvelun valvonta
    services.gatus.settings.endpoints = [{
      name = "Radicale";
      url = "https://${catalog.services.radicale.public.domain}";
      conditions = [ "[STATUS] == 200" ];
    }];
  };
}