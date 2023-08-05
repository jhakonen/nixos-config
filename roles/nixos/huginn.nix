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

  # Luo datakansio
  systemd.services."${config.virtualisation.oci-containers.backend}-huginn".preStart = ''
    mkdir -p ${dataDir}
    chmod 777 ${dataDir}
  '';

  # Puhkaise reikä palomuuriin
  networking.firewall.allowedTCPPorts = [ catalog.services.huginn.port ];

  # Varmuuskopiointi
  services.backup = {
    preHooks = [ "systemctl stop ${config.virtualisation.oci-containers.backend}-huginn.service" ];
    paths = [ dataDir ];
    postHooks = [ "systemctl start ${config.virtualisation.oci-containers.backend}-huginn.service" ];
  };
}
