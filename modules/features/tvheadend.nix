{ self, ... }:
let
  inherit (self) catalog;
  videoGroupId = 26;
in
{
  flake.modules.nixos.tvheadend = { config, ... }: {
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
      image = "lscr.io/linuxserver/tvheadend:latest";
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
    #   Käynnistä: systemctl start restic-backups-tvheadend.service
    #   Snapshotit: sudo restic-tvheadend snapshots
    my.services.restic.backups.tvheadend = {
      repository = "rclone:nas:/backups/restic/tvheadend";
      paths = [ "/var/lib/tvheadend/config" ];
      checkOpts = [ "--read-data" ];
      pruneOpts = [ "--keep-daily 7" "--keep-weekly 4" "--keep-monthly 12" ];
    };

    # Palvelun valvonta
    my.services.monitoring.checks = [
      {
        type = "systemd service";
        description = "Tvheadend - service";
        name = "podman-tvheadend";
      }
      {
        type = "http check";
        description = "Tvheadend - web interface";
        domain = config.networking.hostName;
        port = catalog.services.tvheadend.port;
        path = "/extjs.html";
        response.code = 200;
      }
    ];
  };
}
