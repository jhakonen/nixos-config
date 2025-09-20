{ lib, self, ... }:
let
  inherit (self) catalog;
in {
  flake.modules.nixos.karakeep = { config, pkgs, ... }: {
    age.secrets.karakeep-environment.file = ../../agenix/karakeep-environment.age;

    services.karakeep = {
      enable = true;
      extraEnvironment = {
        DISABLE_SIGNUPS = "true";
        OCR_LANGS = "fin,eng";
        PORT = toString catalog.services.karakeep.port;
      };
      # Sisältää muuttujat NEXTAUTH_SECRET ja OPENAI_API_KEY
      environmentFile = config.age.secrets.karakeep-environment.path;
    };

    # Käytä uudempaa meilisearch versiota, tämän voi poistaa NixOS 25.11 versiossa.
    services.meilisearch.package = pkgs.meilisearch;

    # Paljasta Karakeep karakeep.jhakonen.com domainissa
    services.nginx = {
      enable = true;
      virtualHosts.${catalog.services.karakeep.public.domain} = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString catalog.services.karakeep.port}";
          proxyWebsockets = true;
          recommendedProxySettings = true;
        };
        # Käytä Let's Encrypt sertifikaattia
        addSSL = true;
        useACMEHost = "jhakonen.com";
      };
    };

    # Varmuuskopiointi
    my.services.rsync.jobs.karakeep = {
      destinations = [
        "nas-normal"
        "nas-minimal"
      ];
      preHooks = [ "systemctl stop karakeep-browser.service karakeep-init.service karakeep-web.service karakeep-workers.service" ];
      paths = [ "/var/lib/karakeep" ];
      postHooks = [ "systemctl start karakeep-browser.service karakeep-init.service karakeep-web.service karakeep-workers.service" ];
    };

    # Palvelun valvonta
    my.services.monitoring.checks = [
      {
        type = "systemd service";
        description = "karakeep - service";
        name = "karakeep-web.service";
      }
      {
        type = "http check";
        description = "karakeep - web interface";
        domain = catalog.services.karakeep.public.domain;
        path = "/signin";
        secure = true;
        response.code = 200;
        alertAfterSec = 15 * 60;
      }
    ];
  };
}
