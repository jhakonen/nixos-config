{ lib, pkgs, config, ... }:
let
  cfg = config.roles.backup;
in {
  options.roles.backup = {
    enable = lib.mkEnableOption "Backup rooli";
  };

  config = lib.mkIf cfg.enable {
    # Salaisuudet
    age.secrets = {
      borgbackup-id-rsa.file = ../../secrets/borgbackup-id-rsa.age;
      borgbackup-password.file = ../../secrets/borgbackup-password.age;
    };

    services.backup = {
      enable = true;
      repo = {
        host = "nas";
        user = "borg-backup";
        path = "/volume2/backups/borg/nas-toolbox-nixos";
      };
      paths = [
        "/etc/nixos"
        "/home/jhakonen"
      ];
      excludes = [
        "**/.cache"
        "**/.Trash*"
      ];
      identityFile = config.age.secrets.borgbackup-id-rsa.path;
      passwordFile = config.age.secrets.borgbackup-password.path;
      mounts = {
        "/mnt/borg/kotiautomaatio".remote = "borg-backup@nas:/volume2/backups/borg/nas-kotiautomaatio";
        "/mnt/borg/toolbox".remote        = "borg-backup@nas:/volume2/backups/borg/nas-toolbox-nixos";
        "/mnt/borg/vaultwarden".remote    = "borg-backup@nas:/volume2/backups/borg/vaultwarden";
      };
    };
  };
}