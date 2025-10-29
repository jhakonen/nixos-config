{ lib, ... }:
{
  flake.modules.nixos.service-syncthing = { config, pkgs, ... }: let
    cfg = config.my.services.syncthing;
  in {
    options.my.services.syncthing = {
      enable = lib.mkEnableOption "Syncthing palvelu";
      gui-port = lib.mkOption {
        type = lib.types.int;
        default = 0;
      };
      user = lib.mkOption {
        type = lib.types.str;
        default = "jhakonen";
      };
      data-dir = lib.mkOption {
        type = lib.types.str;
        default = "/home/jhakonen";
      };
      settings = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = {};
      };
    };

    config.services.syncthing = {
      enable = cfg.enable;
      user = cfg.user;
      dataDir = cfg.data-dir;
      overrideDevices = true;
      overrideFolders = true;
      openDefaultPorts = true;
      guiAddress = "0.0.0.0:${toString cfg.gui-port}";
      settings = cfg.settings;
    };

    config.environment.systemPackages = with pkgs; [
      syncthing
    ];

    config.networking.firewall.allowedTCPPorts = lib.mkIf cfg.enable [ cfg.gui-port ];

    # Palvelun valvonta
    config.my.services = lib.mkIf cfg.enable {
      monitoring.checks = [
        {
          type = "systemd service";
          description = "Syncthing - service";
          name = config.systemd.services.syncthing.name;
        }
        {
          type = "http check";
          description = "Syncthing - web interface";
          domain = config.networking.hostName;
          port = cfg.gui-port;
          response.code = 200;
        }
      ];
    };
  };
}
