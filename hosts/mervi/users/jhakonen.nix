{ config, flake, inputs, ... }:
{
  imports = [
    inputs.agenix.homeManagerModules.age

    flake.modules.home.common
    flake.modules.home.mqtt-client
  ];

  age.secrets = {
    jhakonen-mosquitto-password = {
      file = ../../../agenix/mqtt-password.age;
    };
  };

  home.stateVersion = "23.05";
  home.enableNixpkgsReleaseCheck = false;
  roles.mqtt-client.passwordFile = config.age.secrets.jhakonen-mosquitto-password.path;
}
