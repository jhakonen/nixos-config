{ config, catalog, ... }:
{
  age.secrets.node-red-environment.file = ../../secrets/node-red-environment.age;

  services.node-red = {
    enable = true;
    openFirewall = true;
    port = catalog.services.node-red.port;
    define = {
      credentialSecret = "false";
      # "logging.console.level" = "trace";
    };
  };

  systemd.services.node-red.serviceConfig.EnvironmentFile = [
    config.age.secrets.node-red-environment.path
  ];

  services.backup.preHooks = [ "systemctl stop node-red.service" ];
  services.backup.postHooks = [ "systemctl start node-red.service" ];
  services.backup.paths = [ config.services.node-red.userDir ];
}
