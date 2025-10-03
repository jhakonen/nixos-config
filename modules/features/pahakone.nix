{ self, ... }:
{
  flake.modules.nixos.pahakone-tunnel = let
    inherit (self) catalog;
  in {
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
}
