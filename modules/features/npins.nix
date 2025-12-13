{ inputs, ... }: let
  npinsSources = import (inputs.npins + "/npins");
  npinsPkgs = import npinsSources.nixpkgs {};
in {
  flake.modules.nixos.npins = {
    environment.systemPackages = [
      (npinsPkgs.callPackage (inputs.npins + "/npins.nix") {})
    ];
  };
}
