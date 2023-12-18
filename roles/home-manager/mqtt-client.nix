{ config, lib, pkgs, ... }:
let
  cfg = config.roles.mqtt-client;
in {
  options.roles.mqtt-client = {
    passwordFile = lib.mkOption {
      type = lib.types.str;
    };
  };

  config = {
    home.packages = [ pkgs.mosquitto ];
    programs.zsh.shellAliases = {
      mosquitto_sub = "mosquitto_sub -h mqtt.jhakonen.com -p 8883 -u koti -P $(cat ${cfg.passwordFile})";
      mosquitto_pub = "mosquitto_pub -h mqtt.jhakonen.com -p 8883 -u koti -P $(cat ${cfg.passwordFile})";
    };
  };
}
