{
  den.aspects.tunneli.nixos = { config, ... }: {
    services.nginx = {
      enable = true;
      virtualHosts.${config.catalog.services.kalenteri.public.domain} = {
        locations."/" = {
          proxyPass = "https://${config.catalog.nodes.veljen-nassi.ip.tailscale}:20003";
          proxyWebsockets = true;
          recommendedProxySettings = true;
        };
        # Käytä Let's Encrypt sertifikaattia
        addSSL = true;
        useACMEHost = "jhakonen.com";
      };
    };
  };

  den.aspects.kanto.nixos = { config, ... }: {
    # Palvelun valvonta
    services.gatus.settings.endpoints = [{
      name = "Kalenteri";
      url = "https://${config.catalog.services.kalenteri.public.domain}";
      conditions = [ "[STATUS] == 200" ];
    }];
  };
}
