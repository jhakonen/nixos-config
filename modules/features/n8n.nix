{ self, ... }:
let
  inherit (self) catalog;
in
{
  flake.modules.nixos.n8n = { config, ... }: {
    services.n8n = {
      enable = true;
    };

    services.nginx = {
      enable = true;
      virtualHosts.${catalog.services.n8n.public.domain} = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.services.n8n.settings.port}";
          proxyWebsockets = true;
          recommendedProxySettings = true;
        };
        # Käytä Let's Encrypt sertifikaattia
        addSSL = true;
        useACMEHost = "jhakonen.com";
      };
    };

    # Varmuuskopiointi
    my.services.rsync.jobs.n8n = {
      destinations = [
        "nas-normal"
        "nas-minimal"
      ];
      paths = [ "${config.systemd.services.n8n.environment.N8N_USER_FOLDER}/" ];
      preHooks = [ "systemctl stop n8n.service" ];
      postHooks = [ "systemctl start n8n.service" ];
    };

    # Palvelun valvonta
    my.services.monitoring.checks = [
      {
        type = "http check";
        description = "N8N - web interface";
        secure = true;
        domain = catalog.services.n8n.public.domain;
        response.code = 200;
      }
    ];
  };
}
