{ pkgs ? import <nixpkgs> {}, ... }: {
  package = pkgs.callPackage ./koti-go.nix {};
}
