{ pkgs ? import <nixpkgs> {}, ... }:
let
  lgpio = pkgs.callPackage ./lgpio.nix {};
in
{
  wait-button-press = pkgs.callPackage ./wait-button-press { inherit lgpio; };
}
