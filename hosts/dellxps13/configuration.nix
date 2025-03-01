# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, flake, inputs, lib, perSystem, pkgs, ... }:
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
  nix.package = pkgs.lix;
  # Ota flaket käyttöön
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.substituters = [
    # devenv.sh tarvitsee tämän
    "https://devenv.cachix.org"
    "https://cache.nixos.org/"
  ];
  nix.settings.trusted-public-keys = [
    "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
  ];

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

    inputs.agenix.nixosModules.default
    inputs.home-manager.nixosModules.home-manager
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-pc-laptop
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    inputs.nur.modules.nixos.default

    flake.modules.nixos.service-rsync
    flake.modules.nixos.service-monitoring
    flake.modules.nixos.service-syncthing

    flake.modules.nixos.beeper
    flake.modules.nixos.common-programs
    flake.modules.nixos.koti
    flake.modules.nixos.nix-cleanup
    flake.modules.nixos.tailscale
    flake.modules.nixos.zsh
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # boot.kernelPatches = [
  #   # Korjaa toimimattomat äänilaitteet
  #   #   https://discourse.nixos.org/t/no-sound-after-upgrade-dell-xps/52085/2
  #   {
  #     name = "fuck-your-soundwire";
  #     patch = pkgs.fetchurl {
  #       url = "https://github.com/torvalds/linux/commit/233a95fd574fde1c375c486540a90304a2d2d49f.diff";
  #       hash = "sha256-E7K1gLmjwvk93m/dom19gXkBj3/o+5TLZGamv9Oesv0=";
  #     };
  #   }
  # ];

  networking.hostName = "dellxps13"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Yhteys GL-iNet reititimeen katkeilee jos sekä WIFI että Ethernet yhteys on
  # päällä samaan aikaan. Kierrä ongelma laittamalla WIFI pois päältä kun
  # läppäri on verkossa telakan kautta.
  # Skripti otettu Arch Linuxin wikistä: https://wiki.archlinux.org/title/NetworkManager
  networking.networkmanager.dispatcherScripts = [{
    source = pkgs.writeShellScript "wlan_auto_toggle.sh" ''
      if [ "$1" = "enp6s0" ]; then
          case "$2" in
              up)
                  ${pkgs.networkmanager}/bin/nmcli radio wifi off
                  ;;
              down)
                  ${pkgs.networkmanager}/bin/nmcli radio wifi on
                  ;;
          esac
      elif [ "$(${pkgs.networkmanager}/bin/nmcli -g GENERAL.STATE device show enp6s0)" = "20 (unavailable)" ]; then
          ${pkgs.networkmanager}/bin/nmcli radio wifi on
      fi
    '';
    type = "basic";
  }];

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

  # Konfiguroi verkkotulostimen tuki
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
  services.printing.enable = true;

  hardware.bluetooth.enable = true;

  # Enable sound with pipewire.
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

  # Ota Flirc USB-mokkulan ohjelmointityökalut käyttöön
  hardware.flirc.enable = true;

  # Salaisuudet
  age.secrets = {
    jhakonen-rsyncbackup-password = {
      file = ../../agenix/rsyncbackup-password.age;
      owner = "jhakonen";
    };
    rsyncbackup-password.file = ../../agenix/rsyncbackup-password.age;
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
    jobs.jhakonen = {
      paths = [ "/home/jhakonen/" ];
      excludes = [
        "/.cache"
        "/.Trash*"
        "/.local/share/Trash"
        "/.local/share/baloo"
        "/.steam"
        "/Calibre"
        "/Keepass"
        "/Nextcloud"
      ];
      destinations = [
        "nas-normal"
        {
          destination = "nas-minimal";
          excludes = [
            "/.local/share/Steam"
          ];
        }
      ];
    };
  };

  services.openssh = {
    enable = true;
    settings = {
      # Vaadi SSH sisäänkirjautuminen käyttäen vain yksityistä avainta
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # Thunderbolt tuki
  services.hardware.bolt.enable = true;

  my.services.syncthing = {
    enable = true;
    gui-port = flake.lib.catalog.services.syncthing-dellxps13.port;
    settings = {
      devices = flake.lib.catalog.pickSyncthingDevices ["mervi" "nas"];
      folders = {
        "Calibre" = {
          path = "/home/jhakonen/Calibre";
          devices = [ "nas" ];
        };
        "Jaot" = {
          path = "/home/jhakonen/Jaot";
          devices = [ "nas" ];
        };
        "Keepass" = {
          path = "/home/jhakonen/Keepass";
          devices = [ "mervi" "nas" ];
        };
        "Muistiinpanot" = {
          path = "/home/jhakonen/Muistiinpanot";
          devices = [ "nas" ];
        };
      };
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.jhakonen = {
    isNormalUser = true;
    description = "Janne Hakonen";
    extraGroups = [
      "adbusers"
      "dialout"  # Sarjaportin käyttöoikeus
      "networkmanager"
      "vboxusers"
      "wheel"
    ];
    openssh.authorizedKeys.keys = [ id-rsa-public-key ];
  };
  users.users.root = {
    openssh.authorizedKeys.keys = [ id-rsa-public-key ];
  };

  #home-manager.users.jhakonen = import ./home.nix;
  home-manager.users.root.home.stateVersion = "23.11";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    aspell
    aspellDicts.en
    aspellDicts.fi
    bitwarden
    brave
    cachix
    chromium
    nur.repos.shadowrz.klassy-qt6  # KDE6+ teema
    discord
    easyeffects
    git-crypt
    google-chrome  # Chromecastin tukea varten
    haruna  # video soitin
    gnumake
    (hakuneko.overrideAttrs(attrs: {  # Manga downloader
      version = "8.3.4";
      src = pkgs.fetchurl {
        url = "https://github.com/manga-download/hakuneko/releases/download/nightly-20200705.1/hakuneko-desktop_8.3.4_linux_amd64.deb";
        sha256 = "sha256-SOmncBVpX+aTkKyZtUGEz3k/McNFLRdPz0EFLMsq4hE=";
      };
      postFixup = ''
        makeWrapper ${steam-run}/bin/steam-run $out/bin/hakuneko \
          --add-flags $out/lib/hakuneko-desktop/hakuneko \
          "''${gappsWrapperArgs[@]}"
      '';
    }))
    immich-cli
    # itch  # itch.io - Riippuu rikkinäisestä butler kirjastosta
    keepassxc
    lazygit
    libreoffice
    livecaptions
    kdePackages.isoimagewriter
    kdePackages.kaccounts-integration  # Lisää KDE asetuksiin Verkkotilit osion
    kdePackages.kaccounts-providers  # Lisää Verkkotilit osioon mahdollisuudeksi asentaa NextCloud tilin
    kdePackages.kdeconnect-kde
    kdePackages.kmahjongg
    kdePackages.kolourpaint
    kdePackages.plasma-thunderbolt  # Asetusvälilehti thunderboltille (lisäksi services.hardware.bolt)
    kdePackages.qtwebsockets  # Tarvitaan Home Assistant plasmoidia varten
    kdePackages.kcalc
    kdePackages.signond  # Tarvitaan Nextcloud tilin lisäämiseen
    mcomix
    meld
    moonlight-qt
    mqttx
    nextcloud-client
    obsidian
    renameutils  # qmv
    sublime4
    syncthingtray-minimal
    teams-for-linux
    trayscale
    vlc
    zoom-us

    perSystem.nixpkgs-unstable.errands
    perSystem.nixpkgs-unstable.nixos-rebuild-ng
    perSystem.nixpkgs-unstable.tidal-hifi
    perSystem.self.replace-plasma
  ];

  # Esimerkki miten ohjelman paketin voi overridata käyttäen overlaytä
  # nixpkgs.overlays = [
  #   (final: prev: {
  #     ohjelma = prev.ohjelma.overrideAttrs (o: {
  #       patches = (o.patches or [ ]) ++ [
  #         ./polku/patch/tiedostoon.diff
  #       ];
  #     });
  #   })
  # ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  programs.adb.enable = true;

  # Ota AppImage tuki käyttöön
  # programs.appimage = {
  #   enable = true;
  #   binfmt = true;
  # };

  programs.steam.enable = true;

  programs.dconf.enable = true;  # Easyeffects tarvitsee tämän

  programs.direnv = {
    enable = true;
    silent = true;
  };

  programs.zsh.shellAliases = {
    lg = "lazygit";
    qmv = "qmv --editor='subl --launch-or-new-window --wait' --format=destination-only --verbose";
  };

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

  # https://github.com/NixOS/nixpkgs/issues/180175#issuecomment-1473408913
  systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;

  # Ota Oracle Virtualbox tuki käyttöön
  virtualisation.virtualbox.host = {
    enable = true;
    enableExtensionPack = true;
  };
}
