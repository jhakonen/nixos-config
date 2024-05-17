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
    destination = "nas";
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

  # Lisää rooli lokiriveihin jotka Promtail lukee
  systemd.services.influxdb.serviceConfig.LogExtraFields = "ROLE=influxdb";
}
