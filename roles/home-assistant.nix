{ lib, pkgs, config, ... }:
let
  cfg = config.roles.home-assistant;
  listenPort = 8123;
in {
  options.roles.home-assistant = {
    enable = lib.mkEnableOption "Home Assistant rooli";
  };

  config = lib.mkIf cfg.enable {
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
          external_url = "http://kota.jhakonen.com:${toString listenPort}";
          internal_url = "http://nas-toolbox:${toString listenPort}";
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
        frontend = {};
      };
      extraComponents = [ "default_config" "github" "met" "mqtt" ];
    };
    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      defaultHTTPListenPort = listenPort;
      virtualHosts."kota.jhakonen.com" = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.services.home-assistant.config.http.server_port}/";
          proxyWebsockets = true;
        };
      };
    };
    networking.firewall.allowedTCPPorts = [ listenPort ];
    roles.backup = {
      paths = [ config.services.home-assistant.configDir ];
      preHooks = [ "systemctl stop home-assistant.service" ];
      postHooks = [ "systemctl start home-assistant.service" ];
    };
  };
}
