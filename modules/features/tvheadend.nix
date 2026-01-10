{ inputs, self, ... }:
let
  inherit (self) catalog;
  videoGroupId = 26;
in
{
  flake.modules.nixos.tvheadend = { config, pkgs, ... }: let
    imageSource = inputs.tvheadend-image { inherit pkgs; };
    inherit (imageSource) image_name image_digest;
  in {
    users.users.tvheadend = {
      description = "Tvheadend Service user";
      home        = "/var/lib/tvheadend";
      createHome  = true;
      isSystemUser = true;
      group = "tvheadend";
      uid = 987;
    };
    users.groups.tvheadend = {};

    virtualisation.oci-containers.containers.tvheadend = {
      image = "${image_name}@${image_digest}";
      environment = {
        PUID = toString config.users.users.tvheadend.uid;
        PGID = toString videoGroupId;
        TZ = "Etc/UTC";
        #RUN_OPTS = "";
      };
      volumes = [
        "/var/lib/tvheadend/config:/config:rw"
        "/var/lib/tvheadend/recordings:/recordings:rw"
        "/dev/log:/dev/log:rw"  # laite syslogille
      ];
      ports = [
        "${toString catalog.services.tvheadend.port}:9981"
        "${toString catalog.services.tvheadend.htsp_port}:9982"
      ];
      extraOptions = [
        "--device" "/dev/dri:/dev/dri"
        "--device" "/dev/dvb:/dev/dvb"
      ];
      # Älä loggaa kontin stdout/stderr ulostuloa, käytä sensijaan syslogia jota
      # Tvheadend antaa myös ulos. Tällä saa paremman lokitason tunnistuksen
      log-driver = "none";
      #user = "${toString config.users.users.tvheadend.uid}:${toString videoGroupId}";
    };

    networking.firewall.allowedTCPPorts = [
      catalog.services.tvheadend.port
      catalog.services.tvheadend.htsp_port
    ];

    # Varmuuskopiointi
    #   Käynnistä:
    #     systemctl start restic-backups-tvheadend-oma.service
    #     systemctl start restic-backups-tvheadend-veli.service
    #   Snapshotit:
    #     sudo restic-tvheadend-oma snapshots
    #     sudo restic-tvheadend-veli snapshots
    my.services.restic.backups = let
      bConfig = {
        paths = [ "/var/lib/tvheadend/config" ];
      };
    in {
      tvheadend-oma = bConfig // {
        repository = "rclone:nas-oma:/backups/restic/tvheadend";
        timerConfig.OnCalendar = "01:00";
      };
      tvheadend-veli = bConfig // {
        repository = "rclone:nas-veli:/home/restic/tvheadend";
        timerConfig.OnCalendar = "Sat 02:00";
      };
    };

    # Palvelun valvonta
    my.services.monitoring.checks = [{
      type = "systemd service";
      description = "Tvheadend - service";
      name = "podman-tvheadend";
    }];
  };

  flake.modules.nixos.gatus = {
    # Palvelun valvonta
    services.gatus.settings.endpoints = [{
      name = "Tvheadend";
      url = "http://${catalog.services.tvheadend.host.hostName}:${toString catalog.services.tvheadend.port}";
      conditions = [ "[STATUS] == 200" ];
    } {
      name = "Tvheadend (HTSP)";
      url = "tcp://${catalog.services.tvheadend.host.hostName}:${toString catalog.services.tvheadend.htsp_port}";
      conditions = [ "[CONNECTED] == true" ];
    }];
  };
}
