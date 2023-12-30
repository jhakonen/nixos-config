# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ catalog, config, pkgs, ... }:

{
  # Ota flaket käyttöön
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # Poista duplikaatteja storesta, säästäen tilaa
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    # Poista automaattisesti vanhoja nix paketteja ja sukupolvia
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 60d";
  };

  imports = [
    ./hardware-configuration.nix
    ../../modules/backup.nix
    ../../roles/nixos/common-programs.nix
    ../../roles/nixos/zsh.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Helsinki";

  # Select internationalisation properties.
  i18n.defaultLocale = "fi_FI.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "fi_FI.UTF-8";
    LC_IDENTIFICATION = "fi_FI.UTF-8";
    LC_MEASUREMENT = "fi_FI.UTF-8";
    LC_MONETARY = "fi_FI.UTF-8";
    LC_NAME = "fi_FI.UTF-8";
    LC_NUMERIC = "fi_FI.UTF-8";
    LC_PAPER = "fi_FI.UTF-8";
    LC_TELEPHONE = "fi_FI.UTF-8";
    LC_TIME = "fi_FI.UTF-8";
  };

  # Salaisuudet
  age.secrets = {
    borgbackup-id-rsa.file = ../../secrets/borgbackup-id-rsa.age;
    borgbackup-password.file = ../../secrets/borgbackup-password.age;
  };
  # Määrittele avain jolla voidaan purkaa salaus (normaalisti voisi käyttää
  # openssh palvelun host avainta, mutta se vaatisi openssh palvelun käyttöönoton)
  age.identityPaths = [ "/home/jhakonen/.ssh/id_rsa" ];

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  # Configure keymap in X11
  services.xserver = {
    layout = "fi";
    xkbVariant = "nodeadkeys";
  };

  # Configure console keymap
  console.keyMap = "fi";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Varmuuskopiointi
  services.backup = {
    enable = true;
    repo = {
      host = catalog.nodes.nas.hostName;
      user = "borg-backup";
      path = "/volume2/backups/borg/dellxps13-nixos";
    };
    paths = [
      "/home/jhakonen"
    ];
    excludes = [
      "**/.cache"
      "**/.Trash*"
      "**/backup"
      "**/Nextcloud"
    ];
    identityFile = config.age.secrets.borgbackup-id-rsa.path;
    passwordFile = config.age.secrets.borgbackup-password.path;
    mounts = {
      "/mnt/borg/dellxps13".remote = "borg-backup@${catalog.nodes.nas.hostName}:/volume2/backups/borg/dellxps13-nixos";
    };
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.jhakonen = {
    isNormalUser = true;
    description = "Janne Hakonen";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  home-manager.users.root = {
    # Tarvitaan varmuuskopiointia varten
    home.stateVersion = "23.11";
    programs.ssh.enable = true;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    pkgs.unstable.beeper
    bitwarden
    brave
    firefox
    gnumake
    itch  # itch.io
    kate
    libsForQt5.kaccounts-integration  # Lisää KDE asetuksiin Verkkotilit osion
    libsForQt5.kaccounts-providers  # Lisää Verkkotilit osioon mahdollisuudeksi asentaa NextCloud tilin
    libsForQt5.kmahjongg
    libsForQt5.qt5.qtwebsockets  # Tarvitaan Home Assistant plasmoidia varten
    libsForQt5.signond  # Tarvitaan Nextcloud tilin lisäämiseen
    meld
    moonlight-qt
    nextcloud-client
    obsidian
    spotify
    sublime4
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  programs.steam.enable = true;

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

  nixpkgs.config.permittedInsecurePackages = [
    "electron-25.9.0"
    "openssl-1.1.1w"
  ];

  # Lisää swappiä jotta nix-index komennolle riittää muistia
  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 16 * 1024;  # koko megatavuissa
  }];

  services.fwupd.enable = true;
}
