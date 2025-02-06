{ config, pkgs, ... }:
let
  catalog = config.dep-inject.catalog;
  backupDir = "/var/backup/influxdb";
in {
  # Työkalut influxdb varmuuskopiointiin ja palatukseen
  environment.systemPackages = [ pkgs.influxdb ];

  services.influxdb = {
    enable = true;
    extraConfig.http.bind-address = ":${toString catalog.services.influx-db.port}";
  };

  # Influxdb:n käynnistys saattaa kestää, anna lisää aikaa
  systemd.services.influxdb.serviceConfig.TimeoutStartSec = "5min";


  # Varmuuskopiointi
  my.services.rsync.jobs.influxdb = {
    destinations = [
      "nas-normal"
      "nas-minimal"
    ];
    paths = [ "${backupDir}/" ];
    preHooks = [
      ''
      rm -rf ${backupDir}
      ${pkgs.influxdb}/bin/influxd backup -portable ${backupDir}
      systemctl stop influxdb.service
      ''
    ];
    postHooks = [ "systemctl start influxdb.service" ];
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
}
