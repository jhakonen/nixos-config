{ config, ... }: let
  inherit (config) catalog;
in {
  den.aspects.nginx.nixos = { config, pkgs, ... }: {
    # Salaisuudet
    age.secrets.acme-joker-credentials.file = ../../agenix/acme-joker-credentials.age;

    # Palomuurin asetukset
    networking.firewall.allowedTCPPorts = [ 80 443 ];  # nginx

    # Määrittele Let's Encryptin asetukset
    security.acme = {
      acceptTerms = true;
      defaults = {
        email = catalog.acmeEmail;
        dnsProvider = "joker";
        credentialsFile = config.age.secrets.acme-joker-credentials.path;
      };
    };

    services.nginx = {
      enable = true;
      virtualHosts.default = {
        default = true;
        # Vastaa määrittelemättömään domainiin tai porttiin 403 virheellä
        locations."/".extraConfig = ''
          deny all;
        '';
      };
    };

    # Anna nginxille pääsy let's encrypt serifikaattiin
    users.users.nginx.extraGroups = [ "acme" ];
  };
}
