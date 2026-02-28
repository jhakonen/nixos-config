{ lib, config, inputs, ... }: let
  inherit (config) catalog;
in {
  den.default.nixos = { config, ... }: {
    users.users.jhakonen = {
      openssh.authorizedKeys.keys = [ catalog.id-rsa-public-key ];
      isNormalUser = true;
      extraGroups = [
        "wheel"  # Salli sudon käyttö
      ] ++ (lib.optionals config.networking.networkmanager.enable [
        "networkmanager"  # https://wiki.nixos.org/wiki/NetworkManager
      ]);
    };
  };

  den.aspects.jhakonen.homeManager = { config, pkgs, ... }: let
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
      mosquitto_sub = "mosquitto_sub -h ${catalog.services.mosquitto.public.domain} -p 8883 -u koti -P $(cat ${passwordFile})";
      mosquitto_pub = "mosquitto_pub -h ${catalog.services.mosquitto.public.domain} -p 8883 -u koti -P $(cat ${passwordFile})";
    };
  };
}
