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
    my.services.rsync.jobs.immich = {
      destinations = [
        "nas-normal"
        "nas-minimal"
      ];
      paths = [ config.services.immich.mediaLocation ];
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
      {
        type = "http check";
        description = "immich - web interface";
        domain = catalog.services.immich.public.domain;
        secure = true;
        response.code = 200;
        alertAfterSec = 15 * 60;
      }
    ];
  };
}
