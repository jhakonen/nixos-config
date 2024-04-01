{ lib, pkgs, config, ... }:
let
  cfg = config.my.services.syncthing;
in {
  options.my.services.syncthing = {
    enable = lib.mkEnableOption "Syncthing palvelu";
    gui-port = lib.mkOption {
      type = lib.types.int;
      default = 0;
    };
    settings = lib.mkOption {
      type = lib.types.attrs;
      default = {};
    };
  };

  config.services.syncthing = {
    enable = cfg.enable;
    user = "jhakonen";
    dataDir = "/home/jhakonen";
    overrideDevices = true;
    overrideFolders = true;
    openDefaultPorts = true;
    guiAddress = "0.0.0.0:${toString cfg.gui-port}";
    settings = cfg.settings;
  };

  config.networking.firewall.allowedTCPPorts = lib.mkIf cfg.enable [ cfg.gui-port ];
}
