{ config, ... }:
let
  inherit (config) catalog;
  backupDir = "/var/backup/influxdb";
in {
  den.aspects.kanto.nixos = { config, pkgs, ... }: {
    # Työkalut influxdb varmuuskopiointiin ja palatukseen
    environment.systemPackages = [ pkgs.influxdb ];

    services.influxdb = {
      enable = true;
      extraConfig.http.bind-address = ":${toString catalog.services.influx-db.port}";
    };

    # Influxdb:n käynnistys saattaa kestää, anna lisää aikaa
    systemd.services.influxdb.serviceConfig.TimeoutStartSec = "5min";


    # Varmuuskopiointi
    #   Käynnistä:
    #     systemctl start restic-backups-influxdb-oma.service
    #     systemctl start restic-backups-influxdb-veli.service
    #   Snapshotit:
    #     sudo restic-influxdb-oma snapshots
    #     sudo restic-influxdb-veli snapshots
    my.services.restic.backups = let
      bConfig = {
        paths = [ backupDir ];
        backupPrepareCommand = ''
          rm -rf ${backupDir}
          ${pkgs.influxdb}/bin/influxd backup -portable ${backupDir}
          systemctl stop influxdb.service
        '';
        backupCleanupCommand = "systemctl start influxdb.service";
      };
    in {
      influxdb-oma = bConfig // {
        repository = "rclone:nas-oma:/backups/restic/influxdb";
        timerConfig.OnCalendar = "01:00";
      };
      influxdb-veli = bConfig // {
        repository = "rclone:nas-veli:/home/restic/influxdb";
        timerConfig.OnCalendar = "Sat 02:00";
      };
    };

    # Palvelun valvonta
    services.gatus.settings.endpoints = [{
      name = "Influx DB";
      url = "http://${catalog.services.influx-db.host.ip.private}:${toString catalog.services.influx-db.port}/ping";
      conditions = [ "[STATUS] == 204" ];
    }];
  };
}
