{ lib, pkgs, config, home-manager, ... }:
with lib;
let
  cfg = config.apps.backup;
in {
  options.apps.backup = {
    enable = mkEnableOption "Backup app";
    repo = {
      host = mkOption {
        type = types.str;
      };
      user = mkOption {
        type = types.str;
      };
      path = mkOption {
        type = types.str;
      };
    };
    paths = mkOption {
      type = types.listOf types.str;
    };
    excludes = mkOption {
      type = types.listOf types.str;
    };
    identityFile = mkOption {
      type = types.str;
    };
    passwordFile = mkOption {
      type = types.str;
    };
    mounts = mkOption {
      default = {};
      type = types.attrsOf (types.submodule [({ name, ... }: {
        options = {
          local = mkOption {
            type = types.str;
          };
          remote = mkOption {
            type = types.str;
          };
        };
        config = {
          local = name;
        };
      })]);
    };
  };

  config = mkIf cfg.enable {
    home-manager.users.root.programs.ssh.matchBlocks."${cfg.repo.user}@${cfg.repo.host}" = {
      match = "host ${cfg.repo.host} user ${cfg.repo.user}";
      identityFile = cfg.identityFile;
      checkHostIP = false;
    };

    environment.systemPackages = mkIf (cfg.mounts != {}) [
      # Mahdollista fuse.borgfs mount tyypin käyttö
      (pkgs.writeScriptBin "mount.fuse.borgfs" ''
        #!/bin/sh
        export BORG_PASSCOMMAND="${pkgs.coreutils-full}/bin/cat ${cfg.passwordFile}"
        exec ${pkgs.borgbackup}/bin/borgfs "$@"
      '')
    ];

    services.borgbackup.jobs."${cfg.repo.host}" = {
      paths = cfg.paths;
      exclude = cfg.excludes;
      encryption = {
        mode = "repokey-blake2";
        passCommand = "cat ${cfg.passwordFile}";
      };
      repo = "${cfg.repo.user}@${cfg.repo.host}:${cfg.repo.path}";
      compression = "auto,zstd";
      startAt = "daily";
      prune.keep = {
        daily = 3;
        weekly = 4;
        monthly = 12;
        yearly = 2;
      };
    };

    fileSystems = listToAttrs(map (mount: {
      name = mount.local;
      value = {
        device = mount.remote;
        fsType = "fuse.borgfs";
        options = [ "x-systemd.automount" "noauto" "x-systemd.after=network-online.target"
                    "x-systemd.mount-timeout=90" "x-systemd.idle-timeout=1min" "allow_other" ];
      };
    }) (attrValues cfg.mounts));
  };
}
