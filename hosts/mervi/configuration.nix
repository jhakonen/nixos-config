# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:
let
  inherit (config.dep-inject) catalog my-packages private;

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

  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../modules
      ../../roles/nixos/common-programs.nix
      ../../roles/nixos/gamepads.nix
      ../../roles/nixos/nix-cleanup.nix
      ../../roles/nixos/sunshine.nix
      ../../roles/nixos/tvheadend.nix
      ../../roles/nixos/zsh.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "mervi"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

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

  services.avahi = {
    enable = true;
    publish = {
      enable = true;
      # Tarvitaan Kodi JSON-RPC mDNS tukea varten (Jotta Kore löytää Kodin automaattisesti)
      userServices = true;
    };
  };

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

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  my.services.monitoring = {
    enable = true;
    acmeHost = "mervi.lan.jhakonen.com";
    virtualHost = catalog.services.monit-mervi.public.domain;
    mqttAlert = {
      address = catalog.services.mosquitto.public.domain;
      port = catalog.services.mosquitto.port;
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
        host = catalog.nodes.nas.hostName;
        path = "::backups/minimal/${config.networking.hostName}";
      };
      nas-normal = {
        username = "rsync-backup";
        passwordFile = config.age.secrets.rsyncbackup-password.path;
        host = catalog.nodes.nas.hostName;
        path = "::backups/normal/${config.networking.hostName}";
      };
    };
  };

  my.services.syncthing = {
    enable = true;
    gui-port = catalog.services.syncthing-mervi.port;
    settings = {
      devices = catalog.syncthing-devices;
      folders = {
        "Keepass" = {
          path = "/home/jhakonen/Keepass";
          devices = [ "dellxps13" "nas" ];
        };
      };
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
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
  home-manager.users = {
    root = {
      imports = [
        ../../roles/home-manager/zsh.nix
      ];
      home.stateVersion = "23.05";
    };
    jhakonen = {
      imports = [
        ../../roles/home-manager/firefox.nix
        ../../roles/home-manager/kodi.nix
        ../../roles/home-manager/mqtt-client.nix
        ../../roles/home-manager/zsh.nix
      ];
      home.stateVersion = "23.05";
      roles.mqtt-client.passwordFile = config.age.secrets.jhakonen-mosquitto-password.path;
      my.programs.firefox = {
        enable = true;
        nur = config.nur;
      };
    };
  };

  # Enable automatic login for the user.
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "jhakonen";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # TODO: Enable itch once is done: https://github.com/NixOS/nixpkgs/issues/298410
    # itch  # itch.io
    kate
    keepassxc
    kodi  # lisää Kodin puuttuvan ikonin
    spotify
    ngrep  # verkkopakettien greppaus, hyödyllinen WoLin testaukseen
    my-packages.kde-hide-cursor-effect
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # Ota Let's Encryptin sertifikaatti käyttöön
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = private.catalog.acmeEmail;
      dnsProvider = "joker";
      credentialsFile = config.age.secrets.acme-joker-credentials.path;
    };
    certs."mervi.lan.jhakonen.com".extraDomainNames = [ "*.mervi.lan.jhakonen.com" ];
  };

  # Salaisuudet
  age.secrets = {
    acme-joker-credentials.file = private.secret-files.acme-joker-credentials;
    jhakonen-mosquitto-password = {
      file = private.secret-files.mqtt-password;
      owner = "jhakonen";
    };
    mosquitto-password.file = private.secret-files.mqtt-password;
    rsyncbackup-password.file = private.secret-files.rsyncbackup-password;
  };

  programs.fcast-receiver = {
    enable = true;
    openFirewall = true;
  };
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

  networking.firewall.allowedTCPPorts = [
    80 443  # nginx
    catalog.services.kodi.port  # Kodi hallintapaneeli + Kore Android appi
  ];

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];

  networking.firewall.allowedUDPPorts = [
    40000  # WoL portti, ei pakollinen mutta tarpeellinen WoLin testaukseen ngrepillä
  ];

  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

  nixpkgs.config.permittedInsecurePackages = [
    "electron-11.5.0"  # itch paketti vaatii tämän
  ];
}
