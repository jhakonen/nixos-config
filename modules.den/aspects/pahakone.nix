{ config, ... }: let
  inherit (config) catalog;
in {
  den.aspects.tunneli.nixos = {
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

  den.aspects.nassuvm.nixos = {
    # Palvelun valvonta
    services.gatus.settings.endpoints = [{
      name = "Kalenteri";
      url = "https://${catalog.services.kalenteri.public.domain}";
      conditions = [ "[STATUS] == 200" ];
    }];
  };
}
