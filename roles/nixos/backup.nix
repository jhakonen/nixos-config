{ catalog, config, pkgs, ... }:
{
  imports = [ ../../modules/backup.nix ];

  # Salaisuudet
  age.secrets = {
    borgbackup-id-rsa-root.file = ../../secrets/borgbackup-id-rsa.age;
    borgbackup-password-root.file = ../../secrets/borgbackup-password.age;
    borgbackup-id-rsa-jhakonen = {
      file = ../../secrets/borgbackup-id-rsa.age;
      owner = "jhakonen";
    };
    borgbackup-password-jhakonen = {
      file = ../../secrets/borgbackup-password.age;
      owner = "jhakonen";
    };
  };

  # Tarvitaan varmuuskopiointia varten
  home-manager.users.root.programs.ssh.enable = true;

  home-manager.users.jhakonen.home.sessionVariables = {
    # Määrittele SSH komento `borg` ohjelmalle komentorivikäyttöä varten
    BORG_RSH = "ssh -o PasswordAuthentication=no -i ${config.age.secrets.borgbackup-id-rsa-jhakonen.path}";
    # Määrittele salasana `borg` ohjelmalle komentorivikäyttöä varten
    BORG_PASSCOMMAND = "${pkgs.coreutils-full}/bin/cat ${config.age.secrets.borgbackup-password-jhakonen.path}";
  };

  # Varmuuskopiointi
  services.backup = {
    enable = true;
    repo = {
      host = catalog.nodes.nas.hostName;
      user = "borg-backup";
    };
    paths = [
      "/home/jhakonen"
    ];
    excludes = [
      "**/.cache"
      "**/.Trash*"
    ];
    identityFile = config.age.secrets.borgbackup-id-rsa-root.path;
    passwordFile = config.age.secrets.borgbackup-password-root.path;
  };
}
