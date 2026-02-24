{ inputs, ... }:
{
  den.ctx.host.nixos = { pkgs, ... }: {
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