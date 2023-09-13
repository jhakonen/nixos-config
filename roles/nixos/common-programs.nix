{ catalog, pkgs, ... }:
{
  # Asenna locate ja updatedb komennot, updatedb ajetaan myös kerran päivässä
  # keskiyöllä
  services.locate = {
    enable = true;
    localuser = null;
    locate = pkgs.plocate;
  };

  environment.systemPackages = with pkgs; [
    btop
    git
    inetutils  # telnet
    nix-index
    usbutils  # lsusb
  ];

  # Estä `inetutils` pakettia korvaamasta `nettools`
  # paketin ohjelmia `ifconfig`, `hostname` ja `dnsdomainname`
  nixpkgs.config.packageOverrides = pkgs: {
    nettools = pkgs.hiPrio pkgs.nettools;
  };
}
