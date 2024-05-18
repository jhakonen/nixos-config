{ config, ... }:
let
  catalog = config.dep-inject.catalog;
in
{
  services.tvheadend = {
    enable = true;
    httpPort = catalog.services.tvheadend-webui.port;
  };
  networking.firewall.allowedTCPPorts = [
    catalog.services.tvheadend-webui.port
  ];

  # Varmuuskopiointi
  my.services.rsync.jobs.tvheadend = {
    destinations = [
      "nas-normal"
      "nas-minimal"
    ];
    paths = [ "/var/lib/tvheadend/.hts" ];
  };

  systemd.services.tvheadend.serviceConfig.LogExtraFields = "ROLE=tvheadend";
}
