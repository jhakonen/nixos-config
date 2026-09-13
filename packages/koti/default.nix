{ pkgs ? import <nixpkgs> {}, ... }: {
  package = pkgs.callPackage ./koti.nix {};
}
