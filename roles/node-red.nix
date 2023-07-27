{ lib, pkgs, config, ... }:
let
  cfg = config.roles.node-red;
in {
  options.roles.node-red = {
    enable = lib.mkEnableOption "Node-Red app";
    environmentFiles = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [];
    };
  };

  config = lib.mkIf cfg.enable {
    services.node-red = {
      enable = true;
      openFirewall = true;
      port = 1880;
      define = {
        credentialSecret = "false";
        # "logging.console.level" = "trace";
      };
    };

    systemd.services.node-red.serviceConfig.EnvironmentFile = cfg.environmentFiles;

    roles.backup.preHooks = [ "systemctl stop node-red.service" ];
    roles.backup.postHooks = [ "systemctl start node-red.service" ];
    roles.backup.paths = [ config.services.node-red.userDir ];
  };
}
