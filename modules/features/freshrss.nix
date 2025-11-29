{ self, ... }:
let
  inherit (self) catalog;
in
{
  flake.modules.nixos.freshrss = { config, pkgs, ... }: {
    age.secrets.freshrss-admin-password = {
      file = ../../agenix/freshrss-admin-password.age;
      owner = config.services.freshrss.user;
    };

    services.freshrss = {
      enable = true;
      baseUrl = "https://${catalog.services.freshrss.public.domain}";
      virtualHost = catalog.services.freshrss.public.domain;
      # Jos salasanaa vaihtaa niin tulee ajaa freshrss-config.service uudelleen
      passwordFile = config.age.secrets.freshrss-admin-password.path;
    };

    # https://github.com/NixOS/nixpkgs/issues/316624
    systemd.services.freshrss-config = {
      restartIfChanged = true;
      serviceConfig.RemainAfterExit = true;
    };

    services.nginx = {
      enable = true;
      virtualHosts.${catalog.services.freshrss.public.domain} = {
        # Käytä Let's Encrypt sertifikaattia
        addSSL = true;
        useACMEHost = "jhakonen.com";
      };
    };

    # Varmuuskopiointi
    #   Käynnistä: systemctl start restic-backups-freshrss.service
    #   Snapshotit: sudo restic-freshrss snapshots
    my.services.restic.backups.freshrss = {
      repository = "rclone:nas:/backups/restic/freshrss";
      paths = [ config.services.freshrss.dataDir ];
      backupPrepareCommand = ''
        systemctl stop freshrss-updater.timer
        systemctl stop freshrss-updater.service
      '';
      backupCleanupCommand = "systemctl start freshrss-updater.timer";
      checkOpts = [ "--read-data" ];
      pruneOpts = [ "--keep-daily 7" "--keep-weekly 4" "--keep-monthly 12" ];
    };

    # Palvelun valvonta
    my.services.monitoring.checks = [
      {
        type = "systemd service";
        description = "FreshRSS - service";
        name = config.systemd.services.phpfpm-freshrss.name;
      }
      {
        type = "systemd service";
        description = "FreshRSS - updater";
        name = config.systemd.services.freshrss-updater.name;
        extraStates = [
          "LAST_RUN_OK"
          "NOT_RUN_YET"
        ];
      }
      {
        type = "http check";
        description = "FreshRSS - web interface";
        secure = true;
        domain = catalog.services.freshrss.public.domain;
        path = "/i/";
        response.code = 200;
      }
    ];
  };

}