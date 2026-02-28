{ inputs, ... }: let
  npinsSources = import (inputs.npins + "/npins");
  npinsPkgs = import npinsSources.nixpkgs {};
in {
  den.aspects.dellxps13.nixos = {
    environment.systemPackages = [
      (npinsPkgs.callPackage (inputs.npins + "/npins.nix") {})
    ];
  };
}
