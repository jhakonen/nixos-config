{ config, lib, ... }:
let
  catalog = config.dep-inject.catalog;
  LOCAL_LIBRARY_PATH = "/var/lib/calibre-library";
in {
  services = {
    calibre-web = {
      enable = true;
      listen = {
        ip = "127.0.0.1";
        port = catalog.services.calibre-web.port;
      };
      options = {
        calibreLibrary = LOCAL_LIBRARY_PATH;
      };
    };

    nginx.virtualHosts.${catalog.services.calibre-web.public.domain} = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.calibre-web.listen.port}";
        recommendedProxySettings = true;
      };
      # Käytä Let's Encrypt sertifikaattia
      addSSL = true;
      useACMEHost = "jhakonen.com";
    };
  };

  my.services.syncthing.settings.folders."Calibre" = {
    path = LOCAL_LIBRARY_PATH;
    devices = [ "nas" ];
  };
}
