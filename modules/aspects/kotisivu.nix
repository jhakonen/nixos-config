{
  den.aspects.tunneli.nixos = { config, ... }: let
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
      openssh.authorizedKeys.keys = [ config.catalog.id-rsa-public-key ];
    };
    users.users.nginx.extraGroups = [ "www-data" ];
  };

  den.aspects.kanto.nixos = {
    # Palvelun valvonta
    services.gatus.settings.endpoints = [{
      name = "Kotisivu";
      url = "https://jhakonen.com";
      conditions = [ "[STATUS] == 200" ];
    }];
  };
}
