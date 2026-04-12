# Tämä vaatii proxyn asentamisen Remarkable tablettiin.
# Ohjeet löytyy täältä:
#   https://ddvk.github.io/rmfakecloud/remarkable/setup/#rmfakecloud-proxy-script
# Root käyttäjän salasanan näkee laitteesta > Settings > Help > Copyrights and licenses.
#
# Yhdistä tabletti USB-johdolla tietokoneeseen.
# $ ssh root@10.11.99.1
# $ wget https://github.com/ddvk/rmfakecloud-proxy/releases/latest/download/installer-rm12.sh
# $ chmod +x installer-rm12.sh
# $ ./installer-rm12.sh install
# > Enter your own cloud url [http(s)://somehost:port] >https://rmfakecloud.kanto.lan.jhakonen.com
#
# Proxyn asennus täytyy tehdä joka kerta uudelleen kun tabletin firmis päivittyy.
{
  den.aspects.kanto.nixos = { config, pkgs, ... }: {
    environment.systemPackages = [ pkgs.unstable.rmfakecloud ];

    services.rmfakecloud = {
      enable = true;
      package = pkgs.unstable.rmfakecloud;
      storageUrl = "https://${config.catalog.services.rmfakecloud.public.domain}";
      # logLevel = "debug";
      port = config.catalog.services.rmfakecloud.port;
      extraSettings = {
        RM_HTTPS_COOKIE = "1";
        RM_TRUST_PROXY = "1";
      };
    };

    services.nginx = {
      enable = true;
      virtualHosts.${config.catalog.services.rmfakecloud.public.domain} = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.catalog.services.rmfakecloud.port}";
          proxyWebsockets = true;
          recommendedProxySettings = true;
        };
        # Käytä Let's Encrypt sertifikaattia
        addSSL = true;
        useACMEHost = "jhakonen.com";
      };
    };
  };
}
