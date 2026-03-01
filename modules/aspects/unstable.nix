{ inputs, ... }:
{
  den.default.nixos = { pkgs, ... }: {
    nixpkgs.overlays = [
      (_final: _prev: {
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