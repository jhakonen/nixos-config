# Lähde: https://github.com/numtide/blueprint/issues/22#issuecomment-2212524113
{ inputs, pkgs, ... }:
{
  _module.args.pkgsUnstable = import inputs.nixpkgs-unstable {
    inherit (pkgs) system;
    config.allowUnfree = true;
  };
}