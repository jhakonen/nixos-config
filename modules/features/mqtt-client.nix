{ inputs, lib, ... }:
{
  flake.modules.homeManager.mqtt-client = { config, pkgs, ... }: let
    passwordFile = config.age.secrets.mosquitto-password.path;
  in {
    imports = [
      inputs.agenix.homeManagerModules.age
    ];

    age.secrets.mosquitto-password = {
      file = ../../agenix/mqtt-password.age;
    };

    home.packages = [ pkgs.mosquitto ];

    home.shellAliases = {
      mosquitto_sub = "mosquitto_sub -h mqtt.jhakonen.com -p 8883 -u koti -P $(cat ${passwordFile})";
      mosquitto_pub = "mosquitto_pub -h mqtt.jhakonen.com -p 8883 -u koti -P $(cat ${passwordFile})";
    };
  };
}
