{ pkgs ? import <nixpkgs> {}, ... }:
rec {
  bt-mqtt-gateway = pkgs.callPackage ./bt-mqtt-gateway.nix { inherit ruuvitag-sensor; };
  lgpio = pkgs.callPackage ./lgpio.nix {};
  ruuvitag-sensor = pkgs.callPackage ./ruuvitag-sensor.nix {};
  wait-button-press = pkgs.callPackage ./wait-button-press { inherit lgpio; };
  kde-hide-cursor-effect = pkgs.callPackage ./kde-hide-cursor-effect.nix {};
}
