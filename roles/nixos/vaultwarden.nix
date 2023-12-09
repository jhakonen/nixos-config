{ config, catalog, lib, ... }:
let
  dataDir = "/var/lib/bitwarden_rs"; # Tämä on kovakoodattu `services.vaultwarden`iin
  backupDir = "${dataDir}-backup";
in
{
  age.secrets.vaultwarden-environment.file = ../../secrets/vaultwarden-environment.age;

  services.vaultwarden = {
    inherit backupDir;
    enable = true;
    config = {
      WEBSOCKET_ENABLED = true;
      SIGNUPS_ALLOWED = false;
      ROCKET_PORT = 8812;
      WEBSOCKET_PORT = 3012;
      DOMAIN = "https://${catalog.services.bitwarden.public.domain}";
      # Debuggausta varten
      # LOG_LEVEL = "debug";
      # EXTENDED_LOGGING = true;
    };
    environmentFile = config.age.secrets.vaultwarden-environment.path;
  };

  system.activationScripts.makeVarBackupDir = lib.stringAfter [ "var" ] ''
    mkdir -m 700 -p ${backupDir}
    chown vaultwarden:vaultwarden ${backupDir}
  '';

  services.nginx.enable = true;
  services.nginx.virtualHosts.${catalog.services.bitwarden.public.domain} = {
    # Käytä Let's Encrypt sertifikaattia
    addSSL = true;
    useACMEHost = "jhakonen.com";
    extraConfig = ''
      # Enable cross-site filter (XSS) and tell browser to block detected attacks
      add_header X-XSS-Protection "1; mode=block";

      # Disallow the site to be rendered within a frame (clickjacking protection)
      add_header X-Frame-Options DENY;
    '';
    # Proxy the Root directory to Rocket
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.vaultwarden.config.ROCKET_PORT}";
      recommendedProxySettings = true;
    };
    # The negotiation endpoint is also proxied to Rocket
    locations."/notifications/hub/negotiate" = {
      proxyPass = "http://127.0.0.1:${toString config.services.vaultwarden.config.ROCKET_PORT}";
      recommendedProxySettings = true;
    };
    # Notifications redirected to the websockets server
    locations."/notifications/hub" = {
      proxyPass = "http://127.0.0.1:${toString config.services.vaultwarden.config.WEBSOCKET_PORT}";
      proxyWebsockets = true;
      recommendedProxySettings = true;
    };
  };

  # Avaa palomuuriin palvelulle reikä
  networking.firewall.allowedTCPPorts = [ catalog.services.bitwarden.public.port ];

  # Varmuuskopiointi
  services.backup.paths = [ backupDir ];

  # Lisää rooli lokiriveihin jotka Promtail lukee
  systemd.services.vaultwarden.serviceConfig.LogExtraFields = "ROLE=vaultwarden";
  systemd.services.backup-vaultwarden.serviceConfig.LogExtraFields = "ROLE=vaultwarden";
}
