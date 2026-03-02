{
  den.aspects.kanto.nixos = { config, ... }: {
    services.kavita = {
      enable = true;
      tokenKeyFile = config.age.secrets.kavita-token-key.path;
      settings.Port = config.catalog.services.kavita.port;
    };

    services.nginx = {
      enable = true;
      virtualHosts.${config.catalog.services.kavita.public.domain} = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.catalog.services.kavita.port}";
          proxyWebsockets = true;
          recommendedProxySettings = true;
        };
        # Käytä Let's Encrypt sertifikaattia
        addSSL = true;
        useACMEHost = "jhakonen.com";
      };
    };

    age.secrets.kavita-token-key = {
      file = ../../agenix/kavita-token-key.age;
      owner = config.services.kavita.user;
      group = config.services.kavita.user;
    };

    # Palvelun valvonta
    services.gatus.settings.endpoints = [{
      name = "Kavita";
      url = "https://${config.catalog.services.kavita.public.domain}";
      conditions = [ "[STATUS] == 200" ];
    }];
  };
}