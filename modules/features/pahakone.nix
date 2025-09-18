{ self, ... }:
{
  flake.modules.nixos.pahakone-tunnel = let
    inherit (self) catalog;
  in {
    services.nginx = {
      enable = true;
      virtualHosts."pahakone.jhakonen.com" = {
        locations."/" = {
          proxyPass = "https://${catalog.nodes.veljen-nassi.ip.tailscale}:20003";
          recommendedProxySettings = true;
        };
        # Käytä Let's Encrypt sertifikaattia
        addSSL = true;
        useACMEHost = "jhakonen.com";
      };
    };
  };
}
