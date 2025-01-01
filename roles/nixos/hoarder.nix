{ config, pkgs, ... }:
let
  inherit (config.dep-inject) catalog private;

  chrome-port = catalog.services.hoarder.port + 1;
  chrome-version = "123";
  hoarder-version = "0.20.0";
  hoarder-dir = "/var/lib/hoarder";
in {
  age.secrets.hoarder-environment.file = private.secret-files.hoarder-environment;

  virtualisation.oci-containers.containers = {
    # Hoarder palvelu
    hoarder-web = {
      image = "ghcr.io/hoarder-app/hoarder:${hoarder-version}";
      volumes = [ "${hoarder-dir}:/data" ];
      environment = {
        BROWSER_WEB_URL = "http://host.containers.internal:${toString chrome-port}";
        DATA_DIR = "/data";
        DISABLE_SIGNUPS = "true";
        MEILI_ADDR = "http://host.containers.internal:${toString config.services.meilisearch.listenPort}";
        OCR_LANGS = "fin,eng";
      };
      environmentFiles = [
        # Sisältää muuttujat NEXTAUTH_SECRET ja OPENAI_API_KEY
        config.age.secrets.hoarder-environment.path
      ];
      ports = [ "${toString catalog.services.hoarder.port}:3000" ];
    };
    # Google Chrome kontissa, Hoarder käyttää webbisivujen lataamiseen
    hoarder-chrome = {
      image = "gcr.io/zenika-hub/alpine-chrome:${chrome-version}";
      cmd = [
        "--no-sandbox"
        "--disable-gpu"
        "--disable-dev-shm-usage"
        "--remote-debugging-address=0.0.0.0"
        "--remote-debugging-port=9222"
        "--hide-scrollbars"
      ];
      ports = [ "${toString chrome-port}:9222" ];
    };
  };

  # Hoarder käyttää meilisearchia hakujen tekoon
  services.meilisearch.enable = true;

  # Paljasta meilisearchin portti jotta hoarder-web kontti saa siihen yhteyttä
  services.meilisearch.listenAddress = "0.0.0.0";
  networking.firewall.allowedTCPPorts = [
    config.services.meilisearch.listenPort
  ];

  # Luo data kansio Hoarderille (kontti ei osaa luoda tätä itse)
  systemd.tmpfiles.rules = [
    "d ${hoarder-dir} 0755 root root"
  ];

  # Paljasta Hoarder hoarder.jhakonen.com domainissa
  services.nginx = {
    enable = true;
    virtualHosts.${catalog.services.hoarder.public.domain} = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString catalog.services.hoarder.port}";
        proxyWebsockets = true;
        recommendedProxySettings = true;
      };
      # Käytä Let's Encrypt sertifikaattia
      addSSL = true;
      useACMEHost = "jhakonen.com";
    };
  };
}
