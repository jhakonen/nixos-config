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

  roles.mqtt-client.passwordFile = config.age.secrets.jhakonen-mosquitto-password.path;

  home.stateVersion = "23.11";
}
