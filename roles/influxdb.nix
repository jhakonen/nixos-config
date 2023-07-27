{ lib, pkgs, config, ... }:
let
  cfg = config.roles.influxdb;
  backupDir = "/var/backup/influxdb";
in {
  options.roles.influxdb = {
    enable = lib.mkEnableOption "Influxdb rooli";
  };

  config = lib.mkIf cfg.enable {
    # Työkalut influxdb varmuuskopiointiin ja palatukseen
    environment.systemPackages = [ pkgs.influxdb ];

    services.influxdb.enable = true;

    services.backup.preHooks = [
      ''
      rm -rf ${backupDir}
      ${pkgs.influxdb}/bin/influxd backup -portable ${backupDir}
      systemctl stop influxdb.service
      ''
    ];
    services.backup.postHooks = [ "systemctl start influxdb.service" ];
    services.backup.paths = [ backupDir ];
  };
}
