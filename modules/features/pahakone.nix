{ self, ... }: let
  inherit (self) catalog;
in {
  flake.modules.nixos.pahakone-tunnel = {
    services.nginx = {
      enable = true;
      virtualHosts.${catalog.services.kalenteri.public.domain} = {
        locations."/" = {
          proxyPass = "https://${catalog.nodes.veljen-nassi.ip.tailscale}:20003";
          proxyWebsockets = true;
          recommendedProxySettings = true;
        };
        # Käytä Let's Encrypt sertifikaattia
        addSSL = true;
        useACMEHost = "jhakonen.com";
      };
    };
  };

  flake.modules.nixos.gatus = {
    # Palvelun valvonta
    services.gatus.settings.endpoints = [{
      name = "Kalenteri";
      url = "https://${catalog.services.kalenteri.public.domain}";
      conditions = [ "[STATUS] == 200" ];
    }];
  };
}
