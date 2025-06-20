{ config, lib, perSystem, pkgs, ... }:
{
  # Asenna locate ja updatedb komennot, updatedb ajetaan myös kerran päivässä
  # keskiyöllä
  services.locate = {
    enable = true;
    package = pkgs.plocate;
  };

  environment.systemPackages = with pkgs; [
    btop
    comma
    file
    git
    inetutils  # telnet
    inotify-info
    isd
    jq
    kitty
    usbutils   # lsusb
    binutils   # strings
    python3
    silver-searcher
    tailspin   # https://github.com/bensadeh/tailspin
    eza        # https://github.com/eza-community/eza
    doggo      # https://doggo.mrkaran.dev/docs/
    nvd        # listaa erot kahden nixos sukupolven väliltä
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
  environment.etc."current-system-packages".text = lib.pipe config.environment.systemPackages [
    (builtins.map (p: "${p.name}"))
    lib.unique
    (builtins.sort builtins.lessThan)
    (builtins.concatStringsSep "\n")
  ];

  # Listaa muuttuneet paketit nixos-rebuild komennon lopussa. Otettu täältä:
  #   https://discourse.nixos.org/t/nvd-simple-nix-nixos-version-diff-tool/12397/42
  system.activationScripts.preActivation = ''
    if [[ -e /run/current-system ]]; then
      echo "--- diff to current-system"
      ${pkgs.nvd}/bin/nvd --nix-bin-dir=${config.nix.package}/bin \
        diff /run/current-system "$systemConfig"
      echo "---"
    fi
  '';
}
