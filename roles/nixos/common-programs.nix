{ catalog, pkgs, ... }:
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
    usbutils   # lsusb
    binutils   # strings
  ];

  # Estä `inetutils` pakettia korvaamasta `nettools`
  # paketin ohjelmia `ifconfig`, `hostname` ja `dnsdomainname`
  nixpkgs.config.packageOverrides = pkgs: {
    nettools = pkgs.hiPrio pkgs.nettools;
  };

  programs.nix-index.enable = true;
  programs.command-not-found.enable = false;
}
