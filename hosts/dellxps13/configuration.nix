# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:
let
  catalog = config.dep-inject.catalog;

  # Julkinen avain SSH:lla sisäänkirjautumista varten
  id-rsa-public-key =
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDMqorF45N0aG+QqJbRt7kRcmXXbsgvXw7"
      + "+cfWuVt6JKLLLo8Tr7YY/HQfAI3+u1TPo+h7NMLfr6E1V3kAHt7M5K+fZ+XYqBvfHT7F8"
      + "jlEsq6azIoLWujiveb7bswvkTdeO/fsg+QZEep32Yx2Na5//9cxdkYYwmmW0+TXemilZH"
      + "l+mVZ8PeZPj+FQhBMsBM+VGJXCZaW+YWEg8/mqGT0p62U9UkolNFfppS3gKGhkiuly/kS"
      + "KjVgSuuKy6h0M5WINWNXKh9gNz9sNnzrVi7jx1RXaJ48sx4BAMJi1AqY3Nu50z4e/wUoi"
      + "AN7fYDxM/AHxtRYg4tBWjuNCaVGB/413h46Alz1Y7C43PbIWbSPAmjw1VDG+i1fOhsXnx"
      + "cLJQqZUd4Jmmc22NorozaqwZkzRoyf+i604QPuFKMu5LDTSfrDfMvkQFY9E1zZgf1LAZT"
      + "LePrfld8YYg/e/+EO0iIAO7dNrxg6Hi7c2zN14cYs+Z327T+/Iqe4Dp1KVK1KQLqJF0Hf"
      + "907fd+UIXhVsd/5ZpVl3G398tYbLk/fnJum4nWUMhNiDQsoEJyZs1QoQFDFD/o1qxXCOo"
      + "Cq0tb5pheaYWRd1iGOY0x2dI6TC2nl6ZVBB6ABzHoRLhG+FDnTWvPTodY1C7rTzUVyWOn"
      + "QZdUqOqF3C79F3f/MCrYk3/CvtbDtQ== jhakonen";
in
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

  nixpkgs = {
    config = {
      allowUnfree = true;
      permittedInsecurePackages = [
        "electron-25.9.0"
        "openssl-1.1.1w"
      ];
    };
  };

  imports = [
    ./hardware-configuration.nix
    ../../roles/nixos/backup.nix
    ../../roles/nixos/common-programs.nix
    ../../roles/nixos/zsh.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "dellxps13"; # Define your hostname.
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
    repo.path = "/volume2/backups/borg/dellxps13-nixos";
    excludes = [
      "**/backup"
      "**/Nextcloud"
    ];
    mounts = {
      "/mnt/borg/dellxps13".remote = "borg-backup@${catalog.nodes.nas.hostName}:/volume2/backups/borg/dellxps13-nixos";
    };
  };

  services.openssh = {
    enable = true;
    settings = {
      # Vaadi SSH sisäänkirjautuminen käyttäen vain yksityistä avainta
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
    # Salli yhteydenotto vain localhostin kautta (tarvitaan lollypopsia varten)
    listenAddresses = [{
      addr = "127.0.0.1";
      port = 22;
    }];
  };

  # Thunderbolt tuki
  services.hardware.bolt.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.jhakonen = {
    isNormalUser = true;
    description = "Janne Hakonen";
    extraGroups = [ "networkmanager" "wheel" ];
    openssh.authorizedKeys.keys = [ id-rsa-public-key ];
  };
  users.users.root = {
    openssh.authorizedKeys.keys = [ id-rsa-public-key ];
  };

  home-manager.users.jhakonen = import ./home.nix;
  home-manager.users.root.home.stateVersion = "23.11";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    beeper
    bitwarden
    brave
    easyeffects
    gnumake
    itch  # itch.io
    kate
    libsForQt5.kaccounts-integration  # Lisää KDE asetuksiin Verkkotilit osion
    libsForQt5.kaccounts-providers  # Lisää Verkkotilit osioon mahdollisuudeksi asentaa NextCloud tilin
    libsForQt5.kdeconnect-kde
    libsForQt5.kmahjongg
    libsForQt5.kolourpaint
    libsForQt5.qt5.qtwebsockets  # Tarvitaan Home Assistant plasmoidia varten
    libsForQt5.kcalc
    # libsForQt5.sddm-kcm  # Lisää KDE asetuksiin Kirjautumisruutu (SSDM) osion
    libsForQt5.signond  # Tarvitaan Nextcloud tilin lisäämiseen
    meld
    moonlight-qt
    nextcloud-client
    obsidian
    plasma5Packages.plasma-thunderbolt  # Asetusvälilehti thunderboltille (lisäksi services.hardware.bolt)
    spotify
    sublime4
    (pkgs.writeShellApplication {
      name = "deploy";
      runtimeInputs = [ ];
      text = ''
        cd /home/jhakonen/nixos-config
        nix run '.' -- "$@"
      '';
    })
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  programs.steam.enable = true;

  programs.dconf.enable = true;  # Easyeffects tarvitsee tämän

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];

  networking.firewall.allowedTCPPortRanges = [
    { from = 1714; to = 1764; }  # KDE Connect
  ];
  networking.firewall.allowedUDPPortRanges = [
    { from = 1714; to = 1764; }  # KDE Connect
  ];

  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

  # Lisää swappiä jotta nix-index komennolle riittää muistia
  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 16 * 1024;  # koko megatavuissa
  }];

  services.fwupd.enable = true;
}
