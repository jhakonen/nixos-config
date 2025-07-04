{
  # Vanhempi networkmanagerin versio joka ei aiheuta virhettä kun yritää
  # yhdistää langattomaan verkkoon.
  # Komento:
  #   $ nmcli device wifi connect <SSID> password <salasana>
  #   > 802-11-wireless-security.key-mgmt: property is missing
  # Raportoitu bugi:
  #   https://gitlab.freedesktop.org/NetworkManager/NetworkManager/-/issues/1688
  flake.modules.nixos.dellxps13 = { pkgs, ... }: let
    # Nixpkgs versio osoitteesta:
    #   https://lazamar.co.uk/nix-versions/?package=networkmanager&version=1.48.10&fullName=networkmanager-1.48.10&keyName=networkmanager&revision=0bd7f95e4588643f2c2d403b38d8a2fe44b0fc73&channel=nixpkgs-unstable#instructions
    old-pkgs = import (builtins.fetchGit {
      name = "nm-1.48.10-for-property-fix";
      url = "https://github.com/NixOS/nixpkgs/";
      ref = "refs/heads/nixpkgs-unstable";
      rev = "0bd7f95e4588643f2c2d403b38d8a2fe44b0fc73";
    }) { system = pkgs.stdenv.system; };
  in {
    networking.networkmanager.package = old-pkgs.networkmanager;
  };
}
