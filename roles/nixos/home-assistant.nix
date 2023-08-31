{ config, catalog, ... }:
let
  listenPort = catalog.services.home-assistant.port;
in {
  services.home-assistant = {
    enable = true;
    config = {
      automation = "!include automations.yaml";
      http = {
        server_port = listenPort;
        use_x_forwarded_for = true;
        trusted_proxies = [ catalog.nodes.nas.ip.private ];
      };
      homeassistant = {
        external_url = "http://${catalog.services.home-assistant.public.domain}";
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
  networking.firewall.allowedTCPPorts = [ listenPort ];
  services.backup = {
    paths = [ config.services.home-assistant.configDir ];
    preHooks = [ "systemctl stop home-assistant.service" ];
    postHooks = [ "systemctl start home-assistant.service" ];
  };

  # Lisää rooli lokiriveihin jotka Promtail lukee
  systemd.services.home-assistant.serviceConfig.LogExtraFields = "ROLE=home-assistant";
}
