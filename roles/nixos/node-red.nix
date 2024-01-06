{ config, ... }:
let
  catalog = config.dep-inject.catalog;
in
{
  age.secrets.node-red-environment.file = ../../secrets/node-red-environment.age;

  services.node-red = {
    enable = true;
    openFirewall = true;
    port = catalog.services.node-red.port;
    define = {
      credentialSecret = "false";
      # "logging.console.level" = "trace";
    };
  };

  services.nginx = {
    enable = true;
    virtualHosts.${catalog.services.node-red.public.domain} = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString catalog.services.node-red.port}";
        recommendedProxySettings = true;
      };
      # Käytä Let's Encrypt sertifikaattia
      addSSL = true;
      useACMEHost = "jhakonen.com";
    };
  };

  # Puhkaise reikä palomuuriin
  networking.firewall.allowedTCPPorts = [ catalog.services.node-red.public.port ];

  systemd.services.node-red.serviceConfig.EnvironmentFile = [
    config.age.secrets.node-red-environment.path
  ];

  services.backup.preHooks = [ "systemctl stop node-red.service" ];
  services.backup.postHooks = [ "systemctl start node-red.service" ];
  services.backup.paths = [ config.services.node-red.userDir ];

  # Lisää rooli lokiriveihin jotka Promtail lukee
  systemd.services.node-red.serviceConfig.LogExtraFields = "ROLE=node-red";
}
