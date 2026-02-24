{ config, ... }: let
  inherit (config) catalog;
in {
  den.ctx.host.nixos = {
    users.users.root = {
      openssh.authorizedKeys.keys = [ catalog.id-rsa-public-key ];
    };
  };
}
