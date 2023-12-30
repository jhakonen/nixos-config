{ lib, pkgs, config, home-manager, ... }:
let
  cfg = config.services.backup;
in {
  options.services.backup = {
    enable = lib.mkEnableOption "Backup service";
    repo = {
      host = lib.mkOption {
        type = lib.types.str;
      };
      user = lib.mkOption {
        type = lib.types.str;
      };
      path = lib.mkOption {
        type = lib.types.str;
      };
    };
    paths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
    };
    excludes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
    };
    identityFile = lib.mkOption {
      type = lib.types.str;
    };
    passwordFile = lib.mkOption {
      type = lib.types.str;
    };
    preHooks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
    };
    postHooks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
    };
    readWritePaths = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [];
    };
    mounts = lib.mkOption {
      default = {};
      type = lib.types.attrsOf (lib.types.submodule [({ name, ... }: {
        options = {
          local = lib.mkOption {
            type = lib.types.str;
          };
          remote = lib.mkOption {
            type = lib.types.str;
          };
        };
        config = {
          local = name;
        };
      })]);
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.root.programs.ssh.matchBlocks."${cfg.repo.user}@${cfg.repo.host}" = {
      match = "host ${cfg.repo.host} user ${cfg.repo.user}";
      identityFile = cfg.identityFile;
      # Ilman tarkistuksen poistoa tulee virhe "Host key verification failed" jos kone ei ole
      # .ssh/known_hosts tiedostossa. Tämä on luultavasti ok sisäverkossa.
      extraOptions.StrictHostKeyChecking = "no";
    };

    environment.variables = {
      # Määrittele SSH komento `borg` ohjelmalle komentorivikäyttöä varten
      BORG_RSH = "ssh -o PasswordAuthentication=no -i ${cfg.identityFile}";
      # Määrittele salasana `borg` ohjelmalle komentorivikäyttöä varten
      BORG_PASSCOMMAND = "${pkgs.coreutils-full}/bin/cat ${cfg.passwordFile}";
    };

    environment.systemPackages = lib.mkIf (cfg.mounts != {}) [
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
      preHook = lib.mkIf (cfg.preHooks != []) (lib.concatStringsSep "\n" cfg.preHooks);
      postHook = lib.mkIf (cfg.postHooks != []) (lib.concatStringsSep "\n" cfg.postHooks);
      readWritePaths = cfg.readWritePaths ++ [
        "/var/backup"
      ];
    };

    system.activationScripts.makeVarBackupDir = lib.stringAfter [ "var" ] ''
      mkdir -m 755 -p /var/backup
    '';

    fileSystems = lib.listToAttrs(map (mount: {
      name = mount.local;
      value = {
        device = mount.remote;
        fsType = "fuse.borgfs";
        options = [ "x-systemd.automount" "noauto" "x-systemd.after=network-online.target"
                    "x-systemd.mount-timeout=90" "x-systemd.idle-timeout=1min" "allow_other" ];
      };
    }) (lib.attrValues cfg.mounts));

    # Lisää rooli lokiriveihin jotka Promtail lukee
    systemd.services.borgbackup-job-nas.serviceConfig.LogExtraFields = "ROLE=backup";
  };
}
