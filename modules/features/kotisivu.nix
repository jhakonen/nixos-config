{ inputs, self, ... }:
{
  flake.modules.nixos.kotisivu = { config, lib, pkgs, ... }: let
    inherit (self) catalog;
    rootDir = "/var/lib/www";
  in {
    services.nginx = {
      enable = true;
      virtualHosts."jhakonen.com" = {
        root = rootDir;
        # Käytä Let's Encrypt sertifikaattia
        addSSL = true;
        useACMEHost = "jhakonen.com";
      };
    };

    systemd.tmpfiles.rules = [
      "d ${rootDir} 0750 www-data www-data"
    ];

    users.groups.www-data = {};
    users.users.www-data = {
      group = "www-data";
      isNormalUser = true;
      openssh.authorizedKeys.keys = [ catalog.id-rsa-public-key ];
    };
    users.users.nginx.extraGroups = [ "www-data" ];
  };
}
