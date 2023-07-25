{ lib, pkgs, config, ... }:
let
  cfg = config.apps.node-red;
in {
  options.apps.node-red = {
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

    apps.backup.preHooks = [ "systemctl stop node-red.service" ];
    apps.backup.postHooks = [ "systemctl start node-red.service" ];
    apps.backup.paths = [ config.services.node-red.userDir ];
  };
}
