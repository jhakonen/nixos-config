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

  flake.modules.nixos.opencloud-client = { pkgs, ... }: {
    environment.systemPackages = [
      pkgs.unstable.opencloud-desktop
    ];
  };
}
