{ inputs, ... }:
{
  # Vanhempi networkmanagerin versio joka ei aiheuta virhettä kun yritää
  # yhdistää langattomaan verkkoon.
  # Komento:
  #   $ nmcli device wifi connect <SSID> password <salasana>
  #   > 802-11-wireless-security.key-mgmt: property is missing
  # Raportoitu bugi:
  #   https://gitlab.freedesktop.org/NetworkManager/NetworkManager/-/issues/1688
  # Nixpkgs versio osoitteesta:
  #   https://lazamar.co.uk/nix-versions/?package=networkmanager&version=1.48.10&fullName=networkmanager-1.48.10&keyName=networkmanager&revision=0bd7f95e4588643f2c2d403b38d8a2fe44b0fc73&channel=nixpkgs-unstable#instructions
  flake.modules.nixos.dellxps13 = { pkgs, ... }: {
    networking.networkmanager.package = inputs.nixpkgs-for-nm-1-48-10.legacyPackages.${pkgs.stdenv.system}.networkmanager;
  };
}
