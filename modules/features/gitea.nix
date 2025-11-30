{ self, ... }:
let
  inherit (self) catalog;
in
{
  flake.modules.nixos.gitea = { config, pkgs, ... }: {
    services.gitea = {
      enable = true;
      settings.server.ROOT_URL = "https://${catalog.services.gitea.public.domain}";
      settings.server.HTTP_PORT = catalog.services.gitea.port;
      settings.service.DISABLE_REGISTRATION = true;
      settings.server.SSH_PORT = 2222;
      settings.server.START_SSH_SERVER = true;
    };

    networking.firewall.allowedTCPPorts = [ 2222 ];

    services.nginx = {
      enable = true;
      virtualHosts.${catalog.services.gitea.public.domain} = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.services.gitea.settings.server.HTTP_PORT}";
          recommendedProxySettings = true;
          extraConfig = ''
            client_max_body_size 0;
          '';
        };
        # Käytä Let's Encrypt sertifikaattia
        addSSL = true;
        useACMEHost = "jhakonen.com";
      };
    };

    # Varmuuskopiointi
    #   Käynnistä: systemctl start restic-backups-gitea.service
    #   Snapshotit: sudo restic-gitea snapshots
    my.services.restic.backups.gitea = {
      repository = "rclone:nas:/backups/restic/gitea";
      paths = [ config.services.gitea.stateDir ];
      backupPrepareCommand = "systemctl stop gitea.service";
      backupCleanupCommand = "systemctl start gitea.service";
      checkOpts = [ "--read-data" ];
      pruneOpts = [ "--keep-daily 7" "--keep-weekly 4" "--keep-monthly 12" ];
    };

    # Palvelun valvonta
    my.services.monitoring.checks = [{
      type = "http check";
      description = "Gitea - web interface";
      secure = true;
      domain = catalog.services.gitea.public.domain;
      response.code = 200;
    }];
  };

  flake.modules.nixos.gatus = {
    # Palvelun valvonta
    services.gatus.settings.endpoints = [{
      name = "Gitea";
      url = "https://${catalog.services.gitea.public.domain}";
      conditions = [ "[STATUS] == 200" ];
    }];
  };
}