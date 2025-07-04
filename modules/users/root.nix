{ self, ... }: let
  inherit (self) catalog;
in {
  flake.modules.nixos.nixos = {
    users.users.root = {
      openssh.authorizedKeys.keys = [ catalog.id-rsa-public-key ];
    };
  };

  flake.modules.homeManager.root = {
    imports = [
      self.modules.homeManager.common
    ];
  };
}
