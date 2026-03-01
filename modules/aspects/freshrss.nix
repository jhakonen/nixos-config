{ config, ... }:
let
  inherit (config) catalog;
in
{
  den.aspects.kanto.nixos = { config, pkgs, ... }: {
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
    #   Käynnistä:
    #     systemctl start restic-backups-freshrss-oma.service
    #     systemctl start restic-backups-freshrss-veli.service
    #   Snapshotit:
    #     sudo restic-freshrss-oma snapshots
    #     sudo restic-freshrss-veli snapshots
    my.services.restic.backups = let
      bConfig = {
        paths = [ config.services.freshrss.dataDir ];
        backupPrepareCommand = ''
          systemctl stop freshrss-updater.timer
          systemctl stop freshrss-updater.service
        '';
        backupCleanupCommand = "systemctl start freshrss-updater.timer";
      };
    in {
      freshrss-oma = bConfig // {
        repository = "rclone:nas-oma:/backups/restic/freshrss";
        timerConfig.OnCalendar = "01:00";
      };
      freshrss-veli = bConfig // {
        repository = "rclone:nas-veli:/home/restic/freshrss";
        timerConfig.OnCalendar = "Sat 02:00";
      };
    };

    # Palvelun valvonta
    services.gatus.settings.endpoints = [{
      name = "FreshRSS";
      url = "https://${catalog.services.freshrss.public.domain}";
      conditions = [ "[STATUS] == 200" ];
    }];
  };
}