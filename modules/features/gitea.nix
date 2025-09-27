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
    my.services.rsync.jobs.gitea = {
      destinations = [
        "nas-normal"
        "nas-minimal"
      ];
      paths = [ "${config.services.gitea.stateDir}/" ];
      preHooks = [
        "systemctl stop gitea.service"
      ];
      postHooks = [
        "systemctl start gitea.service"
      ];
    };

    # Palvelun valvonta
    my.services.monitoring.checks = [
      {
        type = "http check";
        description = "Gitea - web interface";
        secure = true;
        domain = catalog.services.gitea.public.domain;
        response.code = 200;
      }
    ];
  };

}