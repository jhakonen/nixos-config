{ inputs, self, ... }:
let
  inherit (self) catalog;
in
{
  flake.modules.nixos.service-restic = { config, lib, pkgs, ... }: {
    options.my.services.restic.backups = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {};
    };

    config = {
      age.secrets.restic-password = {
        file = ../../agenix/restic-password.age;
      };
      age.secrets.restic-nas-smb-config = {
        file = ../../agenix/restic-nas-smb-config.age;
      };

      environment.systemPackages = with pkgs; [
        rclone
        restic
      ];

      services.restic.backups = builtins.mapAttrs (name: options:
        {
          initialize = true;
          passwordFile = config.age.secrets.restic-password.path;
          checkOpts = [ "--read-data" ];
          pruneOpts = [
            "--keep-daily 7"
            "--keep-weekly 4"
            "--keep-monthly 12"
            "--keep-yearly 3"
          ];
          rcloneConfigFile = config.age.secrets.restic-nas-smb-config.path;
        } // options
      ) config.my.services.restic.backups;
    };
  };
}
