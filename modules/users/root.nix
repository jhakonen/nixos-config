{ config, ... }: let
  inherit (config) catalog;
in {
  den.default.nixos = {
    users.users.root = {
      openssh.authorizedKeys.keys = [ catalog.id-rsa-public-key ];
    };
  };
}
