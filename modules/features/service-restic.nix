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

      services.restic.backups = builtins.mapAttrs (name: options: lib.mkMerge [
        options
        {
          initialize = true;
          passwordFile = config.age.secrets.restic-password.path;
          pruneOpts = [
            "--keep-daily 14"
            "--keep-weekly 4"
            "--keep-monthly 2"
          ];
          rcloneConfigFile = config.age.secrets.restic-nas-smb-config.path;
        }
      ]) config.my.services.restic.backups;
    };
  };
}
