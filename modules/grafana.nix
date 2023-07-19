{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.apps.grafana;
in {
  options.apps.grafana = {
    enable = mkEnableOption "Grafana app";
  };

  config = mkIf cfg.enable {
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
      };
      provision.datasources.settings = {
        apiVersion = 1;
        datasources = [{
          name = "InfluxDB";
          type = "influxdb";
          url = "http://nas-ubuntu-vm:8086";
          database = "telegraf";
        }];
      };
    };

    networking.firewall.allowedTCPPorts = [ config.services.grafana.settings.server.http_port ];
    apps.backup.paths = [ config.services.grafana.dataDir ];
    apps.backup.preHooks = [ "systemctl stop grafana.service" ];
    apps.backup.postHooks = [ "systemctl start grafana.service" ];
  };
}
