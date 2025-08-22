{ inputs, ... }:
{
  flake.modules.nixos.nixos = { config, pkgs, ... }: {
    nixpkgs.overlays = [
      (final: prev: {
        unstable = import inputs.nixpkgs-unstable {
          config = {
            allowUnfree = true;
          };
          system = pkgs.stdenv.system;
        };
      })
    ];
  };
}
