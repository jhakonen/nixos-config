{ self, ... }:
let
  inherit (self) catalog;
in
{
  flake.modules.nixos.node-red = { config, ... }: {
    age.secrets.node-red-environment.file = ../../agenix/node-red-environment.age;

    services.node-red = {
      enable = true;
      openFirewall = true;
      port = catalog.services.node-red.port;
      define = {
        credentialSecret = "false";
        # "logging.console.level" = "trace";
      };
    };

    services.nginx = {
      enable = true;
      virtualHosts.${catalog.services.node-red.public.domain} = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString catalog.services.node-red.port}";
          proxyWebsockets = true;
          recommendedProxySettings = true;
        };
        # Käytä Let's Encrypt sertifikaattia
        addSSL = true;
        useACMEHost = "jhakonen.com";
      };
    };

    # Puhkaise reikä palomuuriin
    networking.firewall.allowedTCPPorts = [ catalog.services.node-red.public.port ];

    systemd.services.node-red.serviceConfig.EnvironmentFile = [
      config.age.secrets.node-red-environment.path
    ];

    # Varmuuskopiointi
    my.services.rsync.jobs.node-red = {
      destinations = [
        "nas-normal"
        "nas-minimal"
      ];
      preHooks = [ "systemctl stop node-red.service" ];
      postHooks = [ "systemctl start node-red.service" ];
      paths = [ "${config.services.node-red.userDir}/" ];
    };

    # Palvelun valvonta
    my.services.monitoring.checks = [
      {
        type = "systemd service";
        description = "Node-Red - service";
        name = config.systemd.services.node-red.name;
      }
      {
        type = "http check";
        description = "Node-Red - web interface";
        secure = true;
        domain = catalog.services.node-red.public.domain;
        response.code = 200;
      }
    ];
  };
}
