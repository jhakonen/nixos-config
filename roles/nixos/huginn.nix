{ catalog, config, ... }:
let
  dataDir = "/var/lib/huginn/data";
  version = "2d5fcafc507da3e8c115c3479e9116a0758c5375";  # 23.7.2023
in {
  # Luo huginin palvelu kontiin ajoon
  virtualisation.oci-containers.containers.huginn = {
    image = "ghcr.io/huginn/huginn:${version}";
    volumes = [ "${dataDir}:/var/lib/mysql" ];
    ports = [ "${toString catalog.services.huginn.port}:3000" ];
    environment = {
      DOMAIN = catalog.services.huginn.public.domain;
      # Aikavyöhyke Rubyn itse keksimässä muodossa, joten ${config.time.timeZone} -muuttujaa ei voi käyttää :(
      # Vaihtoehdot: https://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html
      TIMEZONE = "Helsinki";
    };
  };

  services.nginx = {
    enable = true;
    virtualHosts.${catalog.services.huginn.public.domain} = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString catalog.services.huginn.port}";
        recommendedProxySettings = true;
      };
      # Käytä Let's Encrypt sertifikaattia
      addSSL = true;
      useACMEHost = "jhakonen.com";
      extraConfig = ''
        # Salli upotus Dashyn iframeen
        add_header Content-Security-Policy "frame-ancestors 'self' https://${catalog.services.dashy.public.domain} ;";
      '';
    };
  };

  systemd.services."${config.virtualisation.oci-containers.backend}-huginn" = {
    # Luo datakansio
    preStart = ''
      mkdir -p ${dataDir}
      chmod 777 ${dataDir}
    '';

    # Lisää rooli lokiriveihin jotka Promtail lukee
    serviceConfig.LogExtraFields = "ROLE=huginn";
  };

  # Puhkaise reikä palomuuriin
  networking.firewall.allowedTCPPorts = [ catalog.services.huginn.public.port ];

  # Varmuuskopiointi
  services.backup = {
    preHooks = [ "systemctl stop ${config.virtualisation.oci-containers.backend}-huginn.service" ];
    paths = [ dataDir ];
    postHooks = [ "systemctl start ${config.virtualisation.oci-containers.backend}-huginn.service" ];
  };
}
