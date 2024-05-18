{ config, ... }:
let
  catalog = config.dep-inject.catalog;
in
{
  services.home-assistant = {
    enable = true;
    config = {
      automation = "!include automations.yaml";
      http = {
        server_port = catalog.services.home-assistant.port;
        use_x_forwarded_for = true;
        trusted_proxies = [
          "127.0.0.1"  # Luota nginx palveluun
        ];
      };
      homeassistant = {
        country = "FI";
        external_url = "https://${catalog.services.home-assistant.public.domain}";
        auth_providers = [
          {
            type = "trusted_networks";
            trusted_networks = [
              "192.168.1.0/24"  # lähiverkko
              "100.0.0.0/8"  # häntäverkko
            ];
            allow_bypass_login = true;
          }
          {
            type = "homeassistant";
          }
        ];
      };
      default_config = {};
    };
    extraComponents = [ "default_config" "github" "met" "mqtt" ];
  };

  services.nginx = {
    enable = true;
    virtualHosts.${catalog.services.home-assistant.public.domain} = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString catalog.services.home-assistant.port}";
        proxyWebsockets = true;
        recommendedProxySettings = true;
      };
      # Käytä Let's Encrypt sertifikaattia
      addSSL = true;
      useACMEHost = "jhakonen.com";
    };
  };

  # Puhkaise reikä palomuuriin
  networking.firewall.allowedTCPPorts = [ catalog.services.home-assistant.public.port ];

  # Varmuuskopiointi
  my.services.rsync.jobs.home-assistant = {
    destinations = [
      "nas-normal"
      "nas-minimal"
    ];
    paths = [ "${config.services.home-assistant.configDir}/" ];
    preHooks = [ "systemctl stop home-assistant.service" ];
    postHooks = [ "systemctl start home-assistant.service" ];
  };

  # Lisää rooli lokiriveihin jotka Promtail lukee
  systemd.services.home-assistant.serviceConfig.LogExtraFields = "ROLE=home-assistant";
}
