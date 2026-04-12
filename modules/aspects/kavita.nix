{ inputs, ... }:
{
  den.aspects.kanto.nixos = { config, pkgs, ... }: let
    imageSource = inputs.kavita-image { inherit pkgs; };
    inherit (imageSource) image_name image_digest;
    dataDirRoot = "/var/lib/kavita";
  in {
    # Palvelukäyttäjä
    users.users.kavita = {
      description = "kavita service user";
      isSystemUser = true;
      group = "kavita";
      uid = 974;
    };
    users.groups.kavita.gid = 967;

    # Docker-kontin määritys
    virtualisation.oci-containers.containers.kavita = {
      image = "${image_name}@${image_digest}";
      environment = {
        PUID = toString config.users.users.kavita.uid;
        PGID = toString config.users.groups.kavita.gid;
        TZ = "Europe/Helsinki";
      };
      volumes = [
        "${dataDirRoot}/config:/config"
        "${dataDirRoot}/data:/data"
      ];
      ports = [
        "${toString config.catalog.services.kavita.port}:5000"
      ];
    };

    # Reverse proxyn asetukset
    services.nginx = {
      enable = true;
      virtualHosts.${config.catalog.services.kavita.public.domain} = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.catalog.services.kavita.port}";
          proxyWebsockets = true;
          recommendedProxySettings = true;
        };
        # Käytä Let's Encrypt sertifikaattia
        addSSL = true;
        useACMEHost = "jhakonen.com";
      };
    };

    # Varmuuskopiointi
    #   Käynnistä:
    #     systemctl start restic-backups-kavita-oma.service
    #     systemctl start restic-backups-kavita-veli.service
    #   Snapshotit:
    #     sudo restic-kavita-oma snapshots
    #     sudo restic-kavita-veli snapshots
    my.services.restic.backups = let
      bConfig = {
        paths = [ dataDirRoot ];
        backupPrepareCommand = "systemctl stop podman-kavita.service";
        backupCleanupCommand = "systemctl start podman-kavita.service";
      };
    in {
      kavita-oma = bConfig // {
        repository = "rclone:nas-oma:/backups/restic/kavita";
        timerConfig.OnCalendar = "01:00";
      };
      kavita-veli = bConfig // {
        repository = "rclone:nas-veli:/home/restic/kavita";
        timerConfig.OnCalendar = "Sat 02:00";
        # Rajaa tarkistetun datan määrää koska backupissa menee 3+ tuntia
        # täydellä tarkistuksella, ja aiheuttaa yhteyden katkeamisen
        checkOpts = [ "--read-data-subset" "10%" ];
      };
    };

    # Palvelun valvonta
    services.gatus.settings.endpoints = [{
      name = "Kavita";
      url = "https://${config.catalog.services.kavita.public.domain}";
      conditions = [ "[STATUS] == 200" ];
    }];
  };
}