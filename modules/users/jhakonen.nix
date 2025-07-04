{ lib, self, ... }: let
  inherit (self) catalog;
in {
  flake.modules.nixos.nixos = { config, ... }: {
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

  flake.modules.homeManager.jhakonen = {
    imports = [
      self.modules.homeManager.common
      self.modules.homeManager.mqtt-client
    ];
  };
}
