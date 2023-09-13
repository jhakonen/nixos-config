{ catalog, ... }:
{
  services.tvheadend = {
    enable = true;
    httpPort = catalog.services.tvheadend-webui.port;
  };
  networking.firewall.allowedTCPPorts = [
    catalog.services.tvheadend-webui.port
  ];

  systemd.services.tvheadend.serviceConfig.LogExtraFields = "ROLE=tvheadend";
}
