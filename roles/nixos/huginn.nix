{ config, ... }:
let
  catalog = config.dep-inject.catalog;
  serviceName = "${config.virtualisation.oci-containers.backend}-huginn";

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
    };
  };

  systemd.services.${serviceName} = {
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
  my.services.rsync.jobs.huginn = {
    destinations = [
      "nas-normal"
      "nas-minimal"
    ];
    paths = [ "${dataDir}/" ];
    preHooks = [ "systemctl stop ${serviceName}.service" ];
    postHooks = [ "systemctl start ${serviceName}.service" ];
  };

  # Palvelun valvonta
  my.services.monitoring.checks = [
    {
      type = "systemd service";
      description = "Huginn - service";
      name = serviceName;
    }
    {
      type = "http check";
      description = "Huginn - web interface";
      secure = true;
      domain = catalog.services.huginn.public.domain;
      response.code = 200;
    }
  ];
}
