{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.apps.influxdb;
  backupDir = "/var/backup/influxdb";
in {
  options.apps.influxdb = {
    enable = mkEnableOption "Influxdb app";
  };

  config = mkIf cfg.enable {
    # Työkalut influxdb varmuuskopiointiin ja palatukseen
    environment.systemPackages = with pkgs; [ influxdb ];

    services.influxdb.enable = true;

    apps.backup.preHooks = [
      ''
      rm -rf ${backupDir}
      ${pkgs.influxdb}/bin/influxd backup -portable ${backupDir}
      systemctl stop influxdb.service
      ''
    ];
    apps.backup.postHooks = [ "systemctl start influxdb.service" ];
    apps.backup.paths = [ backupDir ];
  };
}
