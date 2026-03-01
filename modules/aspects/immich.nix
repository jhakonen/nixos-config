{
  den.aspects.kanto.nixos = { config, pkgs, ... }: {
    environment.systemPackages = [ pkgs.immich-cli ];

    services.immich = {
      enable = true;
      port = config.catalog.services.immich.port;
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
      virtualHosts.${config.catalog.services.immich.public.domain} = {
        locations."/" = {
          proxyPass = "http://[::1]:${toString config.catalog.services.immich.port}";
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
    #   Käynnistä:
    #     systemctl start restic-backups-immich-oma.service
    #     systemctl start restic-backups-immich-veli.service
    #   Snapshotit:
    #     sudo restic-immich-oma snapshots
    #     sudo restic-immich-veli snapshots
    my.services.restic.backups = let
      bConfig = {
        paths = [ config.services.immich.mediaLocation ];
      };
    in {
      immich-oma = bConfig // {
        repository = "rclone:nas-oma:/backups/restic/immich";
        timerConfig.OnCalendar = "01:00";
      };
      immich-veli = bConfig // {
        repository = "rclone:nas-veli:/home/restic/immich";
        timerConfig.OnCalendar = "Sat 02:00";
      };
    };

    # Palvelun valvonta
    services.gatus.settings.endpoints = [{
      name = "Immich";
      url = "https://${config.catalog.services.immich.public.domain}";
      conditions = [ "[STATUS] == 200" ];
    }];
  };
}
