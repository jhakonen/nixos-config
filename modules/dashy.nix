{ lib, pkgs, config, ... }:
let
  version = "2.1.1";

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
      image = "lissy93/dashy:${version}";
      volumes = [ "${configFile}:/app/public/conf.yml" ];
      ports = [ "${toString cfg.port}:80" ];
    };
  };
}
