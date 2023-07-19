# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, agenix, home-manager, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      home-manager.nixosModules.default
    ];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  # virtualisation.docker.enable = true;
  # virtualisation.oci-containers.backend = "docker";

  networking.hostName = "nas-toolbox"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;
  # Salli docker-konteista pääsy isäntäkoneelle
  # networking.firewall.trustedInterfaces = [ "docker0" ];

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

  # Configure keymap in X11
  services.xserver = {
    layout = "fi";
    xkbVariant = "nodeadkeys";
  };

  # Configure console keymap
  console.keyMap = "fi";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.jhakonen = {
    # Julkinen avain SSH:lla sisäänkirjautumista varten
    openssh.authorizedKeys.keys = [(
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
      + "QZdUqOqF3C79F3f/MCrYk3/CvtbDtQ== jhakonen"
    )];
    isNormalUser = true;
    description = "Janne Hakonen";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
  };
  home-manager.users.jhakonen = { pkgs, ... }: {
    home.stateVersion = "23.05";
    programs.bash = {
      enable = true;
      profileExtra = ''
        if [ "$XDG_SESSION_TYPE" = "tty" ]; then
          neofetch
        fi
      '';
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
    inetutils
    neofetch

    agenix.packages."x86_64-linux".default
  ];

  # Estä `inetutils` pakettia korvaamasta `nettools`
  # paketin ohjelmia `ifconfig`, `hostname` ja `dnsdomainname`
  nixpkgs.config.packageOverrides = pkgs: {
    nettools = pkgs.hiPrio pkgs.nettools;
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      # Vaadi SSH sisäänkirjautuminen käyttäen vain yksityistä avainta
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # Ota häntäverkko käyttöön, vaatii lisäksi komennon suorittamisen:
  #   sudo tailscale up
  services.tailscale.enable = true;

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
  system.stateVersion = "23.05"; # Did you read the comment?


  ######### Borgbackup #########
  age.secrets = {
    borgbackup-id-rsa.file = ./secrets/borgbackup-id-rsa.age;
    borgbackup-password.file = ./secrets/borgbackup-password.age;
  };
  services.borgbackup.jobs.backup = {
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
    environment.BORG_RSH = "ssh -o 'StrictHostKeyChecking=no' -i ${config.age.secrets.borgbackup-id-rsa.path}";
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


  ######### Nitter palvelu #########
  services.nitter = {
    enable = true;
    openFirewall = true;
    server = {
      port = 11000;
      hostname = "nitter.jhakonen.com";
    };
  };
  # 14.7.2023: Käännä Nitterin uusin master jossa on search fixi mukana
  nixpkgs.overlays = [(final: prev: {
    nitter = prev.nitter.overrideAttrs (old: {
      src = prev.fetchFromGitHub {
        owner = "zedeus";
        repo = "nitter";
        rev = "afbdbd293e30f614ee288731717868c6d618b55f";
        hash = "sha256-sbhc/R/QlShsnM30BhlWc/NWPBr5MJwxfF57JeBQygQ=";
      };
    });
  })];
}
