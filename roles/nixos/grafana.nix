{ config, catalog, ... }:
{
  services.grafana = {
    enable = true;
    settings = {
      "auth.anonymous" = {
        enabled = true;
        org_name = "Main Org.";
        org_role = "Viewer";
        hide_version = true;
      };
      security.allow_embedding = true;
      server.http_addr = "0.0.0.0";
      server.http_port = catalog.services.grafana.port;
    };
    provision.datasources.settings = {
      apiVersion = 1;
      datasources = [{
        name = "InfluxDB";
        type = "influxdb";
        url = "http://localhost:${toString catalog.services.influx-db.port}";
        database = "telegraf";
      }];
    };
  };

  networking.firewall.allowedTCPPorts = [ config.services.grafana.settings.server.http_port ];
  services.backup.paths = [ config.services.grafana.dataDir ];
  services.backup.preHooks = [ "systemctl stop grafana.service" ];
  services.backup.postHooks = [ "systemctl start grafana.service" ];
}
