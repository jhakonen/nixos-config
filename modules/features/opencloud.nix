{ self, ... }:
let
  inherit (self) catalog;
  dataDir = "/var/lib/opencloud";
  version = "3.5.0";
in
{
  flake.modules.nixos.opencloud = { config, ... }: {
    virtualisation.oci-containers.containers.opencloud = {
      image = "opencloudeu/opencloud-rolling:${version}";
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
    #   Käynnistä: systemctl start restic-backups-opencloud.service
    #   Snapshotit: sudo restic-opencloud snapshots
    my.services.restic.backups.opencloud = {
      repository = "rclone:nas:/backups/restic/opencloud";
      paths = [ dataDir ];
      backupPrepareCommand = "systemctl stop opencloud.service";
      backupCleanupCommand = "systemctl start opencloud.service";
      checkOpts = [ "--read-data-subset" "10%" ];
      pruneOpts = [ "--keep-daily 7" "--keep-weekly 4" "--keep-monthly 12" ];
    };
  };

  flake.modules.nixos.opencloud-tunnel = { config, ... }: {
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

  flake.modules.nixos.opencloud-client = { pkgs, ... }: let
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
}
