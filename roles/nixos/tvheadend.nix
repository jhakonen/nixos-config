{ config, ... }:
let
  catalog = config.dep-inject.catalog;
  videoGroupId = 26;
in
{
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
    ];
    ports = [
      "${toString catalog.services.tvheadend.port}:9981"
      "${toString catalog.services.tvheadend.htsp_port}:9982"
    ];
    extraOptions = [
      "--device" "/dev/dri:/dev/dri"
      "--device" "/dev/dvb:/dev/dvb"
    ];
    #user = "${toString config.users.users.tvheadend.uid}:${toString videoGroupId}";
  };

  networking.firewall.allowedTCPPorts = [
    catalog.services.tvheadend.port
    catalog.services.tvheadend.htsp_port
  ];

  # Varmuuskopiointi
  my.services.rsync.jobs.tvheadend = {
    destinations = [
      "nas-normal"
      "nas-minimal"
    ];
    paths = [ "/var/lib/tvheadend/.hts" ];
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
}
