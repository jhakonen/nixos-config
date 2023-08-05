{ config, catalog, ... }:
{
  # Salaisuudet
  age.secrets = {
    borgbackup-id-rsa.file = ../../secrets/borgbackup-id-rsa.age;
    borgbackup-password.file = ../../secrets/borgbackup-password.age;
  };

  services.backup = {
    enable = true;
    repo = {
      host = catalog.nodes.nas.hostName;
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
      "/mnt/borg/kotiautomaatio".remote = "borg-backup@${catalog.nodes.nas.hostName}:/volume2/backups/borg/nas-kotiautomaatio";
      "/mnt/borg/toolbox".remote        = "borg-backup@${catalog.nodes.nas.hostName}:/volume2/backups/borg/nas-toolbox-nixos";
      "/mnt/borg/vaultwarden".remote    = "borg-backup@${catalog.nodes.nas.hostName}:/volume2/backups/borg/vaultwarden";
    };
  };
}
