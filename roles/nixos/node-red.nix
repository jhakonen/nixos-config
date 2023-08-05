{ config, catalog, ... }:
{
  age.secrets.environment-variables.file = ../../secrets/environment-variables.age;

  services.node-red = {
    enable = true;
    openFirewall = true;
    port = catalog.services.node-red.port;
    define = {
      credentialSecret = "false";
      # "logging.console.level" = "trace";
    };
  };

  systemd.services.node-red.serviceConfig.EnvironmentFile = [ config.age.secrets.environment-variables.path ];

  services.backup.preHooks = [ "systemctl stop node-red.service" ];
  services.backup.postHooks = [ "systemctl start node-red.service" ];
  services.backup.paths = [ config.services.node-red.userDir ];
}
