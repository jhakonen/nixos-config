{ self, ... }:
let
  inherit (self) catalog;
in {
  flake.modules.nixos.immich = { config, pkgs, ... }: {
    environment.systemPackages = [ pkgs.immich-cli ];

    services.immich = {
      enable = true;
      port = catalog.services.immich.port;
    };

    # Ota käyttöön videon laitteistopohjainen koodaustuki
    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
      ];
    };
    users.users.immich.extraGroups = [ "video" "render" ];

    # Paljasta Immich jhakonen.com domainissa
    services.nginx = {
      enable = true;
      virtualHosts.${catalog.services.immich.public.domain} = {
        locations."/" = {
          proxyPass = "http://[::1]:${toString catalog.services.immich.port}";
          proxyWebsockets = true;
          recommendedProxySettings = true;
        };
        extraConfig = ''
          client_max_body_size 50000M;
          proxy_read_timeout   600s;
          proxy_send_timeout   600s;
          send_timeout         600s;
        '';
        # Käytä Let's Encrypt sertifikaattia
        addSSL = true;
        useACMEHost = "jhakonen.com";
      };
    };

    # Varmuuskopiointi
    #   Käynnistä: systemctl start restic-backups-immich.service
    #   Snapshotit: sudo restic-immich snapshots
    my.services.restic.backups.immich = {
      repository = "rclone:nas:/backups/restic/immich";
      paths = [ config.services.immich.mediaLocation ];
      checkOpts = [ "--read-data" ];
      pruneOpts = [ "--keep-daily 7" "--keep-weekly 4" "--keep-monthly 12" ];
    };

    # Palvelun valvonta
    my.services.monitoring.checks = [
      {
        type = "systemd service";
        description = "immich - service";
        name = "immich-server.service";
      }
      {
        type = "systemd service";
        description = "immich - machine learning";
        name = "immich-machine-learning.service";
      }
    ];
  };

  flake.modules.nixos.gatus = {
    # Palvelun valvonta
    services.gatus.settings.endpoints = [{
      name = "Immich";
      url = "https://${catalog.services.immich.public.domain}";
      conditions = [ "[STATUS] == 200" ];
    }];
  };
}
