{ self, ... }:
let
  inherit (self) catalog;
in
{
  flake.modules.nixos.grafana = { config, ... }: {
    services.grafana = {
      enable = true;
      settings = {
        "auth.anonymous" = {
          enabled = true;
          org_name = "Main Org.";
          org_role = "Viewer";
          hide_version = true;
        };
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
          proxyWebsockets = true;
          recommendedProxySettings = true;
        };
        # Käytä Let's Encrypt sertifikaattia
        addSSL = true;
        useACMEHost = "jhakonen.com";
      };
    };

    # Puhkaise reikä palomuuriin
    networking.firewall.allowedTCPPorts = [ catalog.services.grafana.public.port ];

    # Varmuuskopiointi
    #   Käynnistä: systemctl start restic-backups-grafana.service
    #   Snapshotit: sudo restic-grafana snapshots
    my.services.restic.backups.grafana = {
      repository = "rclone:nas:/backups/restic/grafana";
      paths = [ config.services.grafana.dataDir ];
      backupPrepareCommand = "systemctl stop grafana.service";
      backupCleanupCommand = "systemctl start grafana.service";
      checkOpts = [ "--read-data" ];
      pruneOpts = [ "--keep-daily 7" "--keep-weekly 4" "--keep-monthly 12" ];
    };

    # Palvelun valvonta
    my.services.monitoring.checks = [{
      type = "systemd service";
      description = "Grafana - service";
      name = config.systemd.services.grafana.name;
    }];
  };

  flake.modules.nixos.gatus = {
    # Palvelun valvonta
    services.gatus.settings.endpoints = [{
      name = "Grafana";
      url = "https://${catalog.services.grafana.public.domain}";
      conditions = [ "[STATUS] == 200" ];
    }];
  };
}
