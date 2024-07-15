{ config, ... }:
let
  catalog = config.dep-inject.catalog;
in
{
  services.tvheadend = {
    enable = true;
    httpPort = catalog.services.tvheadend.port;
  };
  networking.firewall.allowedTCPPorts = [
    catalog.services.tvheadend.port
    catalog.services.tvheadend.htsp_port
  ];

  # Varmuuskopiointi
  my.services.rsync.jobs.tvheadend = {
    destinations = [
      "nas-normal"
      "nas-minimal"
    ];
    paths = [ "/var/lib/tvheadend/.hts" ];
  };

  # Palvelun valvonta
  my.services.monitoring.checks = [
    {
      type = "systemd service";
      description = "Tvheadend - service";
      name = config.systemd.services.tvheadend.name;
    }
    {
      type = "http check";
      description = "Tvheadend - web interface";
      domain = config.networking.hostName;
      port = catalog.services.tvheadend.port;
      path = "/extjs.html";
      response.code = 200;
    }
  ];

  systemd.services.tvheadend.serviceConfig.LogExtraFields = "ROLE=tvheadend";
}
