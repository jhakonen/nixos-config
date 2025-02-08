{ config, flake, inputs, ... }:
{
  imports = [
    inputs.agenix.homeManagerModules.age

    flake.modules.home.mqtt-client
    flake.modules.home.zsh
  ];

  age.secrets = {
    jhakonen-mosquitto-password = {
      file = inputs.private.secret-files.mqtt-password;
    };
  };

  home.stateVersion = "24.05";
  roles.mqtt-client.passwordFile = config.age.secrets.jhakonen-mosquitto-password.path;
}
