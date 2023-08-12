{ config, catalog, ... }:
let
  listenPort = catalog.services.home-assistant.port;
in {
  services.home-assistant = {
    enable = true;
    config = {
      automation = "!include automations.yaml";
      http = {
        server_port = listenPort + 1;
        use_x_forwarded_for = true;
        trusted_proxies = [ "127.0.0.1" ];
      };
      homeassistant = {
        external_url = "http://${catalog.services.home-assistant.public.domain}:${toString listenPort}";
        internal_url = "http://${catalog.services.home-assistant.host.hostName}:${toString listenPort}";
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
    recommendedProxySettings = true;
    virtualHosts.homeAssistant = {
      serverName = catalog.services.home-assistant.public.domain;
      listen = [{
        addr = "0.0.0.0";
        port = listenPort;
      }];
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.home-assistant.config.http.server_port}/";
        proxyWebsockets = true;
      };
    };
  };
  networking.firewall.allowedTCPPorts = [ listenPort ];
  services.backup = {
    paths = [ config.services.home-assistant.configDir ];
    preHooks = [ "systemctl stop home-assistant.service" ];
    postHooks = [ "systemctl start home-assistant.service" ];
  };
}
