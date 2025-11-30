{ self, ... }:
let
  inherit (self) catalog;
in
{
  flake.modules.nixos.gatus = { config, ... }: {
    services.gatus = {
      enable = true;
      settings = {
        web.port = catalog.services.gatus.port;
        storage = {
          path = "/var/lib/gatus/data.db";
          type = "sqlite";
        };
        endpoints = [
          {
            name = "NAS (admin)";
            url = "https://${catalog.services.nas.host.hostName}:${toString catalog.services.nas.port}";
            conditions = [ "[STATUS] == 200" ];
            client.insecure = true;
          }
          {
            name = "Reititin";
            url = "http://${catalog.services.reititin.host.ip.private}";
            conditions = [ "[STATUS] == 200" ];
          }
        ];
      };
    };

    services.nginx = {
      enable = true;
      virtualHosts.${catalog.services.gatus.public.domain} = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString catalog.services.gatus.port}";
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
