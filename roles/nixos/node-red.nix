{ lib, pkgs, config, ... }:
let
  cfg = config.roles.node-red;
in {
  options.roles.node-red = {
    enable = lib.mkEnableOption "Node-Red rooli";
  };

  config = lib.mkIf cfg.enable {
    age.secrets.environment-variables.file = ../../secrets/environment-variables.age;

    services.node-red = {
      enable = true;
      openFirewall = true;
      port = 1880;
      define = {
        credentialSecret = "false";
        # "logging.console.level" = "trace";
      };
    };

    systemd.services.node-red.serviceConfig.EnvironmentFile = [ config.age.secrets.environment-variables.path ];

    services.backup.preHooks = [ "systemctl stop node-red.service" ];
    services.backup.postHooks = [ "systemctl start node-red.service" ];
    services.backup.paths = [ config.services.node-red.userDir ];
  };
}
