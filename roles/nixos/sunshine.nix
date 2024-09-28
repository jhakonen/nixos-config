{ config, lib, pkgs, ... }:
{
  services.sunshine = {
    enable = true;
    openFirewall = true;
    capSysAdmin = false;
  };

  systemd.user.services.sunshine.path = [ pkgs.steam ];
}
