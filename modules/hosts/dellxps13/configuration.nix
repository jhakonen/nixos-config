# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{ inputs, self, ... }:
{
  flake.modules.nixos.dellxps13 = { config, lib, pkgs, ... }: let
    inherit (self) catalog;
    super-productivity-latest = pkgs.callPackage ../../../packages/super-productivity.nix {};
  in {
    nix.package = pkgs.lix;
    # Ota flaket käyttöön
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    # nix.settings.substituters = [
    #   # devenv.sh tarvitsee tämän
    #   "https://devenv.cachix.org"
    #   "https://cache.nixos.org/"
    # ];
    # nix.settings.trusted-public-keys = [
    #   "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
    # ];

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
      #./hardware-configuration.nix

      inputs.agenix.nixosModules.default
      inputs.home-manager.nixosModules.home-manager
      inputs.nixos-hardware.nixosModules.common-cpu-intel
      inputs.nixos-hardware.nixosModules.common-pc-laptop
      inputs.nixos-hardware.nixosModules.common-pc-ssd
      inputs.nur.modules.nixos.default

      self.modules.nixos.service-rsync
      self.modules.nixos.service-monitoring
      self.modules.nixos.service-syncthing

      self.modules.nixos.beeper
      self.modules.nixos.common
      self.modules.nixos.flatpak
      self.modules.nixos.koti
      self.modules.nixos.nemo
      self.modules.nixos.nix-cleanup
      self.modules.nixos.opencloud-client
      self.modules.nixos.tailscale
      self.modules.nixos.tailscale-receive
      self.modules.nixos.webcamera

      # Hyprland modules
      self.modules.nixos.hyprland
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

    # Hallitse verkkoyhteyttä NetworkManagerilla
    networking.networkmanager.enable = true;

    # Yhteys GL-iNet reititimeen katkeilee jos sekä WIFI että Ethernet yhteys on
    # päällä samaan aikaan. Kierrä ongelma laittamalla WIFI pois päältä kun
    # läppäri on verkossa telakan kautta.
    # Skripti otettu Arch Linuxin wikistä: https://wiki.archlinux.org/title/NetworkManager
    # Skriptin lokituksen näkee komennolla:
    #   journalctl -fu NetworkManager-dispatcher.service
    networking.networkmanager.dispatcherScripts = [{
      source = pkgs.writeShellScript "wlan_auto_toggle.sh" ''
        export LANG=C
        LOG_PREFIX="WiFi Auto-Toggle"
        ETHERNET_INTERFACE="enp6s0"
        echo "$LOG_PREFIX - Starting script, iface=$1, status=$2"

        if [ "$1" = "$ETHERNET_INTERFACE" ]; then
            case "$2" in
                up)
                    echo "$LOG_PREFIX - Ethernet up, turn wifi off"
                    ${pkgs.networkmanager}/bin/nmcli radio wifi off
                    ;;
                down)
                    echo "$LOG_PREFIX - Ethernet down, turn wifi on"
                    ${pkgs.networkmanager}/bin/nmcli radio wifi on
                    ;;
            esac
        else
            STATUS="$(${pkgs.networkmanager}/bin/nmcli -g GENERAL.STATE device show $ETHERNET_INTERFACE 2>&1)"
            echo "$LOG_PREFIX - iface state: '$STATUS'"
            if [ "$STATUS" = "20 (unavailable)" ] || [[ "$STATUS" = *"not found"* ]]; then
                echo "$LOG_PREFIX - Failsafe, turn wifi on"
                ${pkgs.networkmanager}/bin/nmcli radio wifi on
            fi
        fi
      '';
      type = "basic";
    }];

    # Määrittele avain jolla voidaan purkaa salaus (normaalisti voisi käyttää
    # openssh palvelun host avainta, mutta se vaatisi openssh palvelun käyttöönoton)
    age.identityPaths = [ "/home/jhakonen/.ssh/id_rsa" ];

    # Enable the KDE Plasma Desktop Environment.
    services.displayManager.sddm.enable = true;
    services.displayManager.sddm.wayland.enable = true;
    #services.desktopManager.plasma6.enable = true;  # kommentoi pois hyprlandia varten

    # Konfiguroi verkkotulostimen tuki
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
    services.printing.enable = true;

    hardware.bluetooth.enable = true;

    # Enable sound with pipewire.
    services.pulseaudio.enable = false;
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
    age.secrets.rsyncbackup-password.file = ../../../agenix/rsyncbackup-password.age;

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
      gui-port = catalog.services.syncthing-dellxps13.port;
      settings = {
        devices = catalog.pickSyncthingDevices ["mervi" "nas"];
        folders = {
          "Calibre" = {
            path = "/home/jhakonen/Syncthing/Calibre";
            devices = [ "nas" ];
          };
          "Jaot" = {
            path = "/home/jhakonen/Syncthing/Jaot";
            devices = [ "nas" ];
          };
          "Keepass" = {
            path = "/home/jhakonen/Syncthing/Keepass";
            devices = [ "mervi" "nas" ];
          };
          "Muistiinpanot" = {
            path = "/home/jhakonen/Syncthing/Muistiinpanot";
            devices = [ "nas" ];
          };
          "Päiväkirja" = {
            path = "/home/jhakonen/Syncthing/Päiväkirja";
            devices = [ "nas" ];
          };
        };
      };
    };

    users.users.jhakonen.extraGroups = [
      "adbusers"
      "dialout"  # Sarjaportin käyttöoikeus
      "vboxusers"
    ];

    home-manager.backupFileExtension = "hm-backup";

    # List packages installed in system profile. To search, run:
    # $ nix search wget
    environment.systemPackages = with pkgs; [
      aspell
      aspellDicts.en
      aspellDicts.fi
      bitwarden
      brave
      cachix
      calibre
      chromium
      #nur.repos.shadowrz.klassy-qt6  # KDE6+ teema
      discord
      easyeffects
      errands
      eww
      git-crypt
      gnome-text-editor
      google-chrome  # Chromecastin tukea varten
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
      libreoffice
      livecaptions
      logseq
      kdePackages.ark  # Pakkausohjelma (zip, tar.gz, jne...)
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
      nixos-rebuild-ng
      obsidian
      renameutils  # qmv
      seafile-client
      sublime4
      super-productivity-latest
      syncthingtray-minimal
      teams-for-linux
      tidal-hifi
      trayscale
      zoom-us

      inputs.qjournalctl.packages.${pkgs.stdenv.system}.default
      inputs.zen-browser.packages.${pkgs.stdenv.system}.default
      inputs.mypanel.packages.${pkgs.stdenv.system}.default
    ];

    services.flatpak.packages = [
      "app.grayjay.Grayjay"
      "org.gnome.Papers"
      "org.gnome.Showtime"
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

    programs.steam = {
      enable = true;
      package = pkgs.steam.override {
        # Älä näytä steamin pääikkunaa, hyödyllinen kun käynnistää steam pelin
        # pikakuvakkeesta
        extraArgs = "-silent";
      };
    };

    # Ota SSH-agentti käyttöön, tarvitaan jotta KeepassXC pystyy lisäämään SSH
    # avaimet agenttiin
    programs.ssh.startAgent = true;

    programs.dconf.enable = true;  # Easyeffects tarvitsee tämän

    programs.direnv = {
      enable = true;
      silent = true;
    };

    environment.shellAliases = {
      qmv = "qmv --editor='subl --launch-or-new-window --wait' --format=destination-only --verbose";
    };

    # List services that you want to enable:

    # Enable the OpenSSH daemon.
    # services.openssh.enable = true;

    # Open ports in the firewall.
    networking.firewall.allowedTCPPorts = [
      12315  # Grayjay Sync
    ];
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
    system.stateVersion = "25.05"; # Did you read the comment?

    system.rebuild.enableNg = true;

    # Lisää swappiä jotta nix-index komennolle riittää muistia
    swapDevices = [{
      device = "/var/lib/swapfile";
      size = 16 * 1024;  # koko megatavuissa
    }];

    services.fwupd.enable = true;

    services.pipewire.wireplumber.extraConfig.main = {
      "monitor.alsa.rules" = [
        ({
          matches = [({
            "node.name" = "alsa_output.pci-0000_00_1f.3-platform-sof_sdw.HiFi__HDMI1__sink";
          })];
          actions.update-props."node.description" = "Läppäri - HDMI/DP";
        })
        ({
          matches = [({
            "node.name" = "alsa_output.pci-0000_00_1f.3-platform-sof_sdw.HiFi__HDMI2__sink";
          }) ({
            "node.name" = "alsa_output.pci-0000_00_1f.3-platform-sof_sdw.HiFi__HDMI3__sink";
          })];
          actions.update-props."node.disabled" = true;
        })
        ({
          matches = [({
            "node.name" = "alsa_output.pci-0000_00_1f.3-platform-sof_sdw.HiFi__Speaker__sink";
          })];
          actions.update-props."node.description" = "Läppäri - Kaiuttimet";
        })
        ({
          matches = [({
            "node.name" = "alsa_input.pci-0000_00_1f.3-platform-sof_sdw.HiFi__Mic__source";
          })];
          actions.update-props."node.description" = "Läppäri - Mikki";
        })
        ({
          matches = [({
            "node.name" = "alsa_output.usb-CalDigit__Inc._CalDigit_Thunderbolt_3_Audio-00.analog-stereo";
          })];
          actions.update-props."node.description" = "Telakka - Kaiuttimet";
        })
        ({
          matches = [({
              "node.name" = "alsa_input.usb-CalDigit__Inc._CalDigit_Thunderbolt_3_Audio-00.analog-stereo";
          })];
          actions.update-props."node.description" = "Telakka - Mikki";
        })
        ({
          matches = [({
            "node.name" = "alsa_input.usb-046d_HD_Pro_Webcam_C920_AF6A0BDF-02.analog-stereo";
          })];
          actions.update-props."node.description" = "Webbikamera - Mikki";
        })
      ];
    };

    # https://github.com/NixOS/nixpkgs/issues/180175#issuecomment-1473408913
    systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;

    # Ota Oracle Virtualbox tuki käyttöön
    # TODO: systemd-modules-load.service palvelun ajossa kestää 10s kun insertoi vboxnetflt moduulia, miksi?
    # virtualisation.virtualbox.host = {
    #   enable = true;
    #   enableExtensionPack = true;
    # };
  };

  flake.modules.homeManager.dellxps13 = {
    # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
    home.stateVersion = "23.05";
  };
}
