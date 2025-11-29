{ self, ... }:
let
  inherit (self) catalog;
  backupDir = "/var/backup/influxdb";
in {
  flake.modules.nixos.influxdb = { config, pkgs, ... }: {
    # Työkalut influxdb varmuuskopiointiin ja palatukseen
    environment.systemPackages = [ pkgs.influxdb ];

    services.influxdb = {
      enable = true;
      extraConfig.http.bind-address = ":${toString catalog.services.influx-db.port}";
    };

    # Influxdb:n käynnistys saattaa kestää, anna lisää aikaa
    systemd.services.influxdb.serviceConfig.TimeoutStartSec = "5min";


    # Varmuuskopiointi
    #   Käynnistä: systemctl start restic-backups-influxdb.service
    #   Snapshotit: sudo restic-influxdb snapshots
    my.services.restic.backups.influxdb = {
      repository = "rclone:nas:/backups/restic/influxdb";
      paths = [ backupDir ];
      backupPrepareCommand = ''
        rm -rf ${backupDir}
        ${pkgs.influxdb}/bin/influxd backup -portable ${backupDir}
        systemctl stop influxdb.service
      '';
      backupCleanupCommand = "systemctl start influxdb.service";
      checkOpts = [ "--read-data" ];
      pruneOpts = [ "--keep-daily 7" "--keep-weekly 4" "--keep-monthly 12" ];
    };

    # Palvelun valvonta
    my.services.monitoring.checks = [
      {
        type = "systemd service";
        description = "InfluxDB - service";
        name = config.systemd.services.influxdb.name;
      }
      {
        type = "http check";
        description = "InfluxDB - http port";
        domain = catalog.services.influx-db.host.ip.private;
        port = catalog.services.influx-db.port;
        path = "/ping";
        response.code = 204;
      }
    ];
  };
}
