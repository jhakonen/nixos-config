{ config, lib, ... }: let
  inherit (config) catalog;
in {
  den.aspects.kanto.nixos = { config, pkgs, ... }: let
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
          calibreLibrary = catalog.paths.syncthing.calibre;
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
        PathModified = "${catalog.paths.syncthing.calibre}/metadata.db";
      };
    };

    systemd.services.calibre-db-reconnect = {
      description = "Muodosta yhteys Calibren tietokantaan uudelleen";
      serviceConfig = {
        ExecStart = "${pkgs.curl}/bin/curl ${LOCAL_URL}/reconnect";
      };
    };

    my.services.syncthing.settings.folders."Calibre" = {
      path = catalog.paths.syncthing.calibre;
      devices = [ "nas" ];
    };

    # Palvelun valvonta
    my.services.monitoring.checks = [
      {
        type = "systemd service";
        description = "Calibre-Web - service";
        name = config.systemd.services.calibre-web.name;
      }
      {
        type = "systemd service";
        description = "Calibre-Web - db reconnect";
        name = config.systemd.services.calibre-db-reconnect.name;
        extraStates = [
          "LAST_RUN_OK"
          "NOT_RUN_YET"
        ];
      }
    ];

    # Palvelun valvonta
    services.gatus.settings.endpoints = [{
      name = "Calibre Web";
      url = "https://${catalog.services.calibre-web.public.domain}";
      conditions = [ "[STATUS] == 200" ];
    }];
  };
}
