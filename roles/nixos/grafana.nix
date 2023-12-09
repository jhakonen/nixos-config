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

  services.nginx = {
    enable = true;
    virtualHosts.${catalog.services.grafana.public.domain} = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString catalog.services.grafana.port}";
        recommendedProxySettings = true;
      };
      # Käytä Let's Encrypt sertifikaattia
      addSSL = true;
      useACMEHost = "jhakonen.com";
    };
  };

  # Puhkaise reikä palomuuriin
  networking.firewall.allowedTCPPorts = [ catalog.services.grafana.public.port ];

  services.backup.paths = [ config.services.grafana.dataDir ];
  services.backup.preHooks = [ "systemctl stop grafana.service" ];
  services.backup.postHooks = [ "systemctl start grafana.service" ];

  # Lisää rooli lokiriveihin jotka Promtail lukee
  systemd.services.grafana.serviceConfig.LogExtraFields = "ROLE=grafana";
}
