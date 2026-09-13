{
  den.aspects.koti.nixos = { pkgs, ... }: let
    koti = pkgs.callPackage ../../packages/koti/koti.nix { };
  in {
    environment.systemPackages = [ koti ];
  };
}
