{ config, lib, ... }:
let
  catalog = config.dep-inject.catalog;

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

      # Muokkaa Vaultwardenin Content-Security-Policy otsikkoa jotta sen voi
      # upottaa Dashyn iframeen
      set $CSP "default-src 'self';";
      set $CSP "''${CSP} base-uri 'self';";
      set $CSP "''${CSP} form-action 'self';";
      set $CSP "''${CSP} object-src 'self' blob:;";
      set $CSP "''${CSP} script-src 'self' 'wasm-unsafe-eval';";
      set $CSP "''${CSP} style-src 'self' 'unsafe-inline';";
      set $CSP "''${CSP} child-src 'self' https://*.duosecurity.com https://*.duofederal.com;";
      set $CSP "''${CSP} frame-src 'self' https://*.duosecurity.com https://*.duofederal.com;";
      set $CSP "''${CSP} frame-ancestors 'self'";
      set $CSP "''${CSP}   chrome-extension://nngceckbapebfimnlniiiahkandclblb";
      set $CSP "''${CSP}   chrome-extension://jbkfoedolllekgbhcbcoahefnbanhhlh moz-extension://*";
      set $CSP "''${CSP}   moz-extension://*";
      set $CSP "''${CSP}   https://${catalog.services.dashy.public.domain} ;";
      set $CSP "''${CSP} img-src 'self' data: https://haveibeenpwned.com https://www.gravatar.com ;";
      set $CSP "''${CSP} connect-src 'self' https://api.pwnedpasswords.com https://api.2fa.directory https://app.simplelogin.io/api/ https://app.anonaddy.com/api/ https://api.fastmail.com/;";
      proxy_hide_header Content-Security-Policy;
      add_header Content-Security-Policy "''${CSP}" always;
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
