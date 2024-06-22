{ config, lib, pkgs, ... }:
let
  catalog = config.dep-inject.catalog;
  LOCAL_LIBRARY_PATH = "/var/lib/calibre-library";
  LOCAL_URL = "http://127.0.0.1:${toString config.services.calibre-web.listen.port}";
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
        proxyPass = LOCAL_URL;
        recommendedProxySettings = true;
      };
      # Käytä Let's Encrypt sertifikaattia
      addSSL = true;
      useACMEHost = "jhakonen.com";
    };
  };

  systemd.services.calibre-web.serviceConfig.Environment = [
    "CALIBRE_RECONNECT=1"
  ];

  systemd.paths.calibre-web-db-watcher = {
    description = "Päivitä calibre-webin sisältö kun tietokantaa muutetaan Calibresta";
    wantedBy = [ "multi-user.target" ];
    pathConfig = {
      Unit = "calibre-db-reconnect.service";
      PathModified = "${LOCAL_LIBRARY_PATH}/metadata.db";
    };
  };

  systemd.services.calibre-db-reconnect = {
    description = "Muodosta yhteys Calibren tietokantaan uudelleen";
    serviceConfig = {
      ExecStart = "${pkgs.curl}/bin/curl ${LOCAL_URL}/reconnect";
    };
  };

  my.services.syncthing.settings.folders."Calibre" = {
    path = LOCAL_LIBRARY_PATH;
    devices = [ "nas" ];
  };

  # Palvelun valvonta
  my.services.monitoring.checks = [
    {
      type = "systemd service";
      description = "Calibre-Web - service";
      name = config.systemd.services.calibre-web.name;
      expected = "running";
    }
    {
      type = "systemd service";
      description = "Calibre-Web - db reconnect";
      name = config.systemd.services.calibre-db-reconnect.name;
      expected = "succeeded";
    }
    {
      type = "http check";
      description = "Calibre-Web - web interface";
      secure = true;
      domain = catalog.services.calibre-web.public.domain;
      path = "/login";
      response.code = 200;
    }
  ];
}
