{ config, flake, inputs, ... }:
{
  imports = [
    inputs.agenix.homeManagerModules.age

    flake.modules.home.mqtt-client
    flake.modules.home.zsh
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
