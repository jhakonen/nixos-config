{ inputs, config, ... }:
let
  inherit (config) catalog;
  dataDir = "/var/lib/opencloud";
in
{
  den.aspects.kanto.nixos = { config, pkgs, ... }: let
    imageSource = inputs.opencloud-image { inherit pkgs; };
    inherit (imageSource) image_name image_digest;
  in {
    virtualisation.oci-containers.containers.opencloud = {
      image = "${image_name}@${image_digest}";
      serviceName = "opencloud";
      environment = {
        # enable services that are not started automatically
        #OC_ADD_RUN_SERVICES = "${START_ADDITIONAL_SERVICES}";
        OC_URL = "https://${catalog.services.opencloud.public.domain}";
        #OC_LOG_LEVEL = "${LOG_LEVEL:-info}";
        #OC_LOG_COLOR = "${LOG_PRETTY:-false}";
        #OC_LOG_PRETTY = "${LOG_PRETTY:-false}";
        # do not use SSL between the reverse proxy and OpenCloud
        PROXY_TLS = "false";
        # INSECURE = needed if OpenCloud / reverse proxy is using self generated certificates;
        # OC_INSECURE = "${INSECURE:-false}";
        # basic auth (not recommended, but needed for eg. WebDav clients that do not support OpenID Connect)
        # PROXY_ENABLE_BASIC_AUTH = "${PROXY_ENABLE_BASIC_AUTH:-false}";
      };
      volumes = [
        "${dataDir}/config:/etc/opencloud"
        "${dataDir}/data:/var/lib/opencloud"
        "${dataDir}/apps:/var/lib/opencloud/web/assets/apps"
      ];
      ports = [
        "${toString catalog.services.opencloud.port}:9200"
      ];
    };

    networking.firewall.allowedTCPPorts = [
      catalog.services.opencloud.port
    ];

    systemd.tmpfiles.rules = [
      "d ${dataDir}/config 0777 root root"
      "d ${dataDir}/data 0777 root root"
      "d ${dataDir}/apps 0777 root root"
    ];

    # Vamuuskopiointi
    #   Käynnistä:
    #     systemctl start restic-backups-opencloud-oma.service
    #     systemctl start restic-backups-opencloud-veli.service
    #   Snapshotit:
    #     sudo restic-opencloud-oma snapshots
    #     sudo restic-opencloud-veli snapshots
    my.services.restic.backups = let
      bConfig = {
        paths = [ dataDir ];
        backupPrepareCommand = "systemctl stop opencloud.service";
        backupCleanupCommand = "systemctl start opencloud.service";
        checkOpts = [ "--read-data-subset" "10%" ];
      };
    in {
      opencloud-oma = bConfig // {
        repository = "rclone:nas-oma:/backups/restic/opencloud";
        timerConfig.OnCalendar = "01:00";
      };
      opencloud-veli = bConfig // {
        repository = "rclone:nas-veli:/home/restic/opencloud";
        timerConfig.OnCalendar = "Sat 02:00";
      };
    };
  };

  den.aspects.tunneli.nixos = { config, ... }: {
    services.nginx.virtualHosts.${catalog.services.opencloud.public.domain} = {
      locations."/" = {
        proxyPass = "http://kanto.tailscale.jhakonen.com:${toString catalog.services.opencloud.port}";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_request_buffering off;
          send_timeout            10h;
        '';
      };
      # Käytä Let's Encrypt sertifikaattia
      addSSL = true;
      useACMEHost = "jhakonen.com";
    };
  };

  den.aspects.dellxsp13.nixos = { pkgs, ... }: let
    # https://github.com/NixOS/nixpkgs/pull/456008 - voinee poistaa NixOS 25.11 versiossa
    ecm618 = pkgs.unstable.kdePackages.extra-cmake-modules.overrideAttrs (old: rec {
      version = "6.18.0";
      src = pkgs.unstable.fetchFromGitLab {
        domain = "invent.kde.org";
        owner = "frameworks";
        repo = "extra-cmake-modules";
        tag = "v${version}";
        hash = "sha256-hpqczRaV32yyXXRWxR30tOBEUNWDkeSzVrv0SHMrz1Y=";
      };
      patches = [ ];
    });
  in {
    environment.systemPackages = [
      (pkgs.unstable.opencloud-desktop.overrideAttrs(attrs: {
        buildInputs = with pkgs.unstable; [
          ecm618
          qt6.qtbase
          qt6.qtdeclarative
          qt6.qttools
          kdePackages.qtkeychain
          libre-graph-api-cpp-qt-client
          kdsingleapplication
        ];
      }))
    ];
  };

  den.aspects.nassuvm.nixos = {
    # Palvelun valvonta
    services.gatus.settings.endpoints = [{
      name = "Opencloud";
      url = "https://${catalog.services.opencloud.public.domain}";
      conditions = [ "[STATUS] == 200" ];
    }];
  };
}
