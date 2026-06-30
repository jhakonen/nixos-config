{
  den.aspects.nginx.nixos = { config, ... }: {
    # Salaisuudet
    age.secrets = {
      acme-joker-credentials.file = ../../agenix/acme-joker-credentials.age;
      dummy-ssl-certificate-file = {
        file = ../../agenix/dummy-ssl-certificate-file.age;
        owner = "nginx";
      };
      dummy-ssl-certificate-key = {
        file = ../../agenix/dummy-ssl-certificate-key.age;
        owner = "nginx";
      };
    };

    # Palomuurin asetukset
    networking.firewall.allowedTCPPorts = [ 80 443 ];  # nginx

    # Määrittele Let's Encryptin asetukset
    security.acme = {
      acceptTerms = true;
      defaults = {
        email = config.catalog.acmeEmail;
        dnsProvider = "joker";
        environmentFile = config.age.secrets.acme-joker-credentials.path;
      };
    };

    services.nginx = {
      enable = true;
      virtualHosts.default = {
        addSSL = true;
        default = true;
        sslCertificate = config.age.secrets.dummy-ssl-certificate-file.path;
        sslCertificateKey = config.age.secrets.dummy-ssl-certificate-key.path;
        locations."/".return = "404";
      };
    };

    # Anna nginxille pääsy let's encrypt serifikaattiin
    users.users.nginx.extraGroups = [ "acme" ];
  };
}
