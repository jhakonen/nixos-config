{ lib, pkgs, config, ... }:
let
  cfg = config.roles.mosquitto;
in {
  options.roles.mosquitto = {
    enable = lib.mkEnableOption "Mosquitto rooli";
    user = lib.mkOption {
      type = lib.types.str;
      default = "koti";
    };
    passwordFile = lib.mkOption {
      type = lib.types.str;
    };
    certficateFile = lib.mkOption {
      type = lib.types.str;
    };
    keyFile = lib.mkOption {
      type = lib.types.str;
    };
  };

  config = lib.mkIf cfg.enable {
    services.mosquitto = {
      enable = true;
      listeners = [
        {
          port = 1883;
          users."${cfg.user}" = {
            acl = [ "#" ];
            passwordFile = cfg.passwordFile;
          };
        }
        {
          port = 8883;
          settings = {
            certfile = cfg.certficateFile;
            keyfile = cfg.keyFile;
          };
          users."${cfg.user}" = {
            acl = [ "#" ];
            passwordFile = cfg.passwordFile;
          };
        }
      ];
    };
    networking.firewall.allowedTCPPorts = [ 1883 8883 ];
  };
}
