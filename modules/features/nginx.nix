{ self, ... }:
{
  flake.modules.nixos.nginx = { config, pkgs, ... }: let
    inherit (self) catalog;
  in {
    # Salaisuudet
    age.secrets = {
      acme-joker-credentials.file = ../../agenix/acme-joker-credentials.age;
    };

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

    services.nginx.virtualHosts.default = {
      default = true;
      # Vastaa määrittelemättömään domainiin tai porttiin 403 virheellä
      locations."/".extraConfig = ''
        deny all;
      '';
    };

    # Anna nginxille pääsy let's encrypt serifikaattiin
    users.users.nginx.extraGroups = [ "acme" ];
  };
}
