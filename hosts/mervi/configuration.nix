# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, flake, inputs, pkgs, ... }:
let
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

  imports = [
    ./hardware-configuration.nix

    inputs.agenix.nixosModules.default
    inputs.home-manager.nixosModules.home-manager

    flake.modules.nixos.service-rsync
    flake.modules.nixos.service-monitoring
    flake.modules.nixos.service-syncthing

    flake.modules.nixos.common-programs
    flake.modules.nixos.gamepads
    flake.modules.nixos.koti
    flake.modules.nixos.nix-cleanup
    flake.modules.nixos.sunshine
    flake.modules.nixos.zsh
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "mervi";

  # Enable networking
  networking.networkmanager.enable = true;
  # Ota Wake-on-Lan (WoL) käyttöön
  networking.interfaces."enp3s0".wakeOnLan.enable = true;

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

  # Enable the X11 windowing system.
  #services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "fi";
    variant = "nodeadkeys";
  };

  # Configure console keymap
  console.keyMap = "fi";

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  my.services.monitoring = {
    enable = true;
    acmeHost = "mervi.lan.jhakonen.com";
    virtualHost = flake.lib.catalog.services.monit-mervi.public.domain;
    mqttAlert = {
      address = flake.lib.catalog.services.mosquitto.public.domain;
      port = flake.lib.catalog.services.mosquitto.port;
      passwordFile = config.age.secrets.mosquitto-password.path;
    };
  };

  # Varmuuskopiointi
  my.services.rsync = {
    enable = true;
    schedule = "*-*-* 0:00:00";
    destinations = {
      nas-minimal = {
        username = "rsync-backup";
        passwordFile = config.age.secrets.rsyncbackup-password.path;
        host = flake.lib.catalog.nodes.nas.hostName;
        path = "::backups/minimal/${config.networking.hostName}";
      };
      nas-normal = {
        username = "rsync-backup";
        passwordFile = config.age.secrets.rsyncbackup-password.path;
        host = flake.lib.catalog.nodes.nas.hostName;
        path = "::backups/normal/${config.networking.hostName}";
      };
    };
  };

  my.services.syncthing = {
    enable = true;
    gui-port = flake.lib.catalog.services.syncthing-mervi.port;
    settings = {
      devices = flake.lib.catalog.pickSyncthingDevices ["dellxps13" "nas"];
      folders = {
        "Keepass" = {
          path = "/home/jhakonen/Keepass";
          devices = [ "dellxps13" "nas" ];
        };
      };
    };
  };

  users.users = {
    jhakonen = {
      openssh.authorizedKeys.keys = [ id-rsa-public-key ];
      isNormalUser = true;
      description = "Janne Hakonen";
      extraGroups = [ "networkmanager" "wheel" ];
      packages = with pkgs; [];
    };

    # Anna nginxille pääsy let's encrypt serifikaattiin
    nginx.extraGroups = [ "acme" ];

    root = {
      openssh.authorizedKeys.keys = [ id-rsa-public-key ];
    };
  };

  # Enable automatic login for the user.
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "jhakonen";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    firefox
    # TODO: Enable itch once is done: https://github.com/NixOS/nixpkgs/issues/298410
    # itch  # itch.io
    keepassxc
    ngrep  # verkkopakettien greppaus, hyödyllinen WoLin testaukseen
    unigine-superposition
  ];

  # Ota Let's Encryptin sertifikaatti käyttöön
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = flake.lib.catalog.acmeEmail;
      dnsProvider = "joker";
      credentialsFile = config.age.secrets.acme-joker-credentials.path;
    };
    certs."mervi.lan.jhakonen.com".extraDomainNames = [ "*.mervi.lan.jhakonen.com" ];
  };

  # Salaisuudet
  age.secrets = {
    acme-joker-credentials.file = ../../agenix/acme-joker-credentials.age;
    jhakonen-rsyncbackup-password = {
      file = ../../agenix/rsyncbackup-password.age;
      owner = "jhakonen";
    };
    mosquitto-password.file = ../../agenix/mqtt-password.age;
    rsyncbackup-password.file = ../../agenix/rsyncbackup-password.age;
  };

  programs.gamemode.enable = true;
  programs.kdeconnect.enable = true;
  programs.steam.enable = true;
  programs.zsh.shellAliases = {
    # Kokeile ottaako kone vastaan WoL paketteja
    wol-listen = "sudo ngrep '\\xff{6}(.{6})\\1{15}' -x port 40000";
  };

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

  services.flatpak.enable = true;

  networking.firewall.allowedTCPPorts = [
    80 443  # nginx
  ];
  networking.firewall.allowedUDPPorts = [
    40000  # WoL portti, ei pakollinen mutta tarpeellinen WoLin testaukseen ngrepillä
  ];

  system.stateVersion = "23.05";
}
