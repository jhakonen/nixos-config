{ lib, pkgs, config, ... }:
let
  # lissy93/dashy:latest @ 7.12.2023
  version = "sha256:097cfe11cf89c9d1b69b2cfbe985c7ba1f8d2ba9906895be37a34de20379d407";

  cfg = config.services.dashy;
  configFile = format.generate "dashy.yaml" cfg.settings;
  format = pkgs.formats.yaml { };
in {
  options.services.dashy = {
    enable = lib.mkEnableOption "Dashy service";
    port = lib.mkOption {
      type = lib.types.int;
      default = 80;
    };
    settings = lib.mkOption {
      type = lib.types.attrs;
      default = {};
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.dashy = {
      image = "lissy93/dashy@${version}";
      # Asetustiedoston sisällön näkee komennolla:
      #   less $(sudo podman inspect dashy | jq -r '.[0].HostConfig.Binds[0] | split(":")[0]')
      volumes = [ "${configFile}:/app/public/conf.yml" ];
      ports = [ "${toString cfg.port}:80" ];
    };

    # Lisää rooli lokiriveihin jotka Promtail lukee
    systemd.services."${config.virtualisation.oci-containers.backend}-dashy"
      .serviceConfig.LogExtraFields = "ROLE=dashy";
  };
}
