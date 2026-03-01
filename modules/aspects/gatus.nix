{
  den.aspects.kanto.nixos = { config, ... }: {
    services.gatus = {
      enable = true;
      settings = {
        web.port = config.catalog.services.gatus.port;
        storage = {
          path = "/var/lib/gatus/data.db";
          type = "sqlite";
        };
        endpoints = [
          {
            name = "NAS (admin)";
            url = "https://${config.catalog.services.nas.host.hostName}:${toString config.catalog.services.nas.port}";
            conditions = [ "[STATUS] == 200" ];
            client.insecure = true;
          }
          {
            name = "Reititin";
            url = "http://${config.catalog.services.reititin.host.ip.private}";
            conditions = [ "[STATUS] == 200" ];
          }
        ];
      };
    };

    services.nginx = {
      enable = true;
      virtualHosts.${config.catalog.services.gatus.public.domain} = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.catalog.services.gatus.port}";
          proxyWebsockets = true;
          recommendedProxySettings = true;
        };
        # Käytä Let's Encrypt sertifikaattia
        addSSL = true;
        useACMEHost = "jhakonen.com";
      };
    };
  };
}
