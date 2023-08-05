{ pkgs, catalog, ... }:
let
  backupDir = "/var/backup/influxdb";
in {
  # Työkalut influxdb varmuuskopiointiin ja palatukseen
  environment.systemPackages = [ pkgs.influxdb ];

  services.influxdb = {
    enable = true;
    extraConfig.http.bind-address = ":${toString catalog.services.influx-db.port}";
  };

  services.backup.preHooks = [
    ''
    rm -rf ${backupDir}
    ${pkgs.influxdb}/bin/influxd backup -portable ${backupDir}
    systemctl stop influxdb.service
    ''
  ];
  services.backup.postHooks = [ "systemctl start influxdb.service" ];
  services.backup.paths = [ backupDir ];
}
