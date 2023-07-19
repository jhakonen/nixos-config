{ config, pkgs, home-manager, ... }:
{
  home-manager.users.root.programs.ssh.matchBlocks."borg-backup@nas" = {
    match = "host nas user borg-backup";
    identityFile = config.age.secrets.borgbackup-id-rsa.path;
    checkHostIP = false;
  };

  environment.systemPackages = [
    # Mahdollista fuse.borgfs mount tyypin käyttö
    (pkgs.writeScriptBin "mount.fuse.borgfs" ''
      #!/bin/sh
      export BORG_PASSCOMMAND="${pkgs.coreutils-full}/bin/cat ${config.age.secrets.borgbackup-password.path}"
      exec ${pkgs.borgbackup}/bin/borgfs "$@"
    '')
  ];

  services.borgbackup.jobs.nas = {
    paths = [
      "/etc/nixos"
      "/home/jhakonen"
    ];
    exclude = [
      "**/.cache"
      "**/.Trash*"
    ];
    encryption = {
      mode = "repokey-blake2";
      passCommand = "cat ${config.age.secrets.borgbackup-password.path}";
    };
    repo = "borg-backup@nas:/volume2/backups/borg/nas-toolbox-nixos";
    compression = "auto,zstd";
    startAt = "daily";
    prune.keep = {
      daily = 3;
      weekly = 4;
      monthly = 12;
      yearly = 2;
    };
  };

  age.secrets = {
    borgbackup-id-rsa.file = ../secrets/borgbackup-id-rsa.age;
    borgbackup-password.file = ../secrets/borgbackup-password.age;
  };

  fileSystems = {
    "/mnt/borg/kotiautomaatio" = {
      device = "borg-backup@nas:/volume2/backups/borg/nas-kotiautomaatio";
      fsType = "fuse.borgfs";
      options = [ "x-systemd.automount" "noauto" "x-systemd.after=network-online.target"
                  "x-systemd.mount-timeout=90" "x-systemd.idle-timeout=1min" "allow_other" ];
    };
    "/mnt/borg/toolbox" = {
      device = "borg-backup@nas:/volume2/backups/borg/nas-toolbox-nixos";
      fsType = "fuse.borgfs";
      options = [ "x-systemd.automount" "noauto" "x-systemd.after=network-online.target"
                  "x-systemd.mount-timeout=90" "x-systemd.idle-timeout=1min" "allow_other" ];
    };
    "/mnt/borg/vaultwarden" = {
      device = "borg-backup@nas:/volume2/backups/borg/vaultwarden";
      fsType = "fuse.borgfs";
      options = [ "x-systemd.automount" "noauto" "x-systemd.after=network-online.target"
                  "x-systemd.mount-timeout=90" "x-systemd.idle-timeout=1min" "allow_other" ];
    };
  };
}
