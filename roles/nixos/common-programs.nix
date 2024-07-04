{ config, lib, pkgs, ... }:
{
  # Asenna locate ja updatedb komennot, updatedb ajetaan myös kerran päivässä
  # keskiyöllä
  services.locate = {
    enable = true;
    localuser = null;
    package = pkgs.plocate;
  };

  environment.systemPackages = with pkgs; [
    btop
    git
    inetutils  # telnet
    inotify-info
    jq
    usbutils   # lsusb
    binutils   # strings
    python3
    tailspin   # https://github.com/bensadeh/tailspin
    eza        # https://github.com/eza-community/eza
    doggo      # https://doggo.mrkaran.dev/docs/
  ];

  # Estä `inetutils` pakettia korvaamasta `nettools`
  # paketin ohjelmia `ifconfig`, `hostname` ja `dnsdomainname`
  nixpkgs.config.packageOverrides = pkgs: {
    nettools = pkgs.hiPrio pkgs.nettools;
  };

  programs.nix-index.enable = true;
  programs.command-not-found.enable = false;

  # Listaa kaikki asennetut paketit polussa /etc/current-system-packages
  # Lähde: https://www.reddit.com/r/NixOS/comments/fsummx/comment/fm45htj/
  environment.etc."current-system-packages".text = let
    packages = builtins.map (p: "${p.name}") config.environment.systemPackages;
    sortedUnique = builtins.sort builtins.lessThan (lib.unique packages);
    formatted = builtins.concatStringsSep "\n" sortedUnique;
  in formatted;
}
