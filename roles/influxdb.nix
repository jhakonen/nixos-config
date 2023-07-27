{ lib, pkgs, config, ... }:
let
  cfg = config.roles.influxdb;
  backupDir = "/var/backup/influxdb";
in {
  options.roles.influxdb = {
    enable = lib.mkEnableOption "Influxdb app";
  };

  config = lib.mkIf cfg.enable {
    # Työkalut influxdb varmuuskopiointiin ja palatukseen
    environment.systemPackages = [ pkgs.influxdb ];

    services.influxdb.enable = true;

    roles.backup.preHooks = [
      ''
      rm -rf ${backupDir}
      ${pkgs.influxdb}/bin/influxd backup -portable ${backupDir}
      systemctl stop influxdb.service
      ''
    ];
    roles.backup.postHooks = [ "systemctl start influxdb.service" ];
    roles.backup.paths = [ backupDir ];
  };
}
