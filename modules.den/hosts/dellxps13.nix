{ config, lib, inputs, den, ... }: let
  inherit (config) catalog;
in {
  imports = [ inputs.den.flakeModule ];

  den.hosts.x86_64-linux.dellxps13.users.jhakonen.aspect = "jhakonen@dellxps13";
  den.aspects."jhakonen@dellxps13".includes = [ den.aspects.jhakonen ];

  den.hosts.x86_64-linux.dellxps13.users.root = {};

  den.aspects.dellxps13 = {
    includes = [
      den.aspects.koti
      den.aspects.tailscale
    ];

    nixos = { config, lib, modulesPath, pkgs, ... }: let
      super-productivity-latest = pkgs.callPackage ../../packages/super-productivity.nix {};
      pkgs-mistral-vibe = import inputs.nixpkgs-mistral-vibe { inherit (pkgs.stdenv) system; };
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
        hostPlatform = "x86_64-linux";
      };

      imports = [
        (modulesPath + "/installer/scan/not-detected.nix")

        inputs.agenix.nixosModules.default
        inputs.nixos-hardware.nixosModules.common-cpu-intel
        inputs.nixos-hardware.nixosModules.common-pc-laptop
        inputs.nixos-hardware.nixosModules.common-pc-ssd
      ];

      # Bootloader.
      boot.extraModulePackages = [ ];
      boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "vmd" "nvme" "usb_storage" "sd_mod" ];
      boot.initrd.kernelModules = [ ];
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
      boot.kernelModules = [ "kvm-intel" ];

      fileSystems."/" = {
        device = "/dev/disk/by-uuid/e2fb0104-bdd5-4cd6-887e-74879a463cb3";
        fsType = "ext4";
      };

      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/87BC-31D4";
        fsType = "vfat";
        options = [ "fmask=0077" "dmask=0077" ];
      };

      swapDevices = [
        { device = "/dev/disk/by-uuid/771ae4c9-c71d-43e0-9016-557281c7556d"; }
        {
          # Lisää swappiä jotta nix-index komennolle riittää muistia
          device = "/var/lib/swapfile";
          size = 16 * 1024;  # koko megatavuissa
        }
      ];

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

      networking.networkmanager = {
        # Hallitse verkkoyhteyttä NetworkManagerilla
        enable = true;

        # Vanhempi networkmanagerin versio joka ei aiheuta virhettä kun yritää
        # yhdistää langattomaan verkkoon.
        # Komento:
        #   $ nmcli device wifi connect <SSID> password <salasana>
        #   > 802-11-wireless-security.key-mgmt: property is missing
        # Raportoitu bugi:
        #   https://gitlab.freedesktop.org/NetworkManager/NetworkManager/-/issues/1688
        # Nixpkgs versio osoitteesta:
        #   https://lazamar.co.uk/nix-versions/?package=networkmanager&version=1.48.10&fullName=networkmanager-1.48.10&keyName=networkmanager&revision=0bd7f95e4588643f2c2d403b38d8a2fe44b0fc73&channel=nixpkgs-unstable#instructions
        package = inputs.nixpkgs-for-nm-1-48-10.legacyPackages.${pkgs.stdenv.system}.networkmanager;

        # Yhteys GL-iNet reititimeen katkeilee jos sekä WIFI että Ethernet yhteys on
        # päällä samaan aikaan. Kierrä ongelma laittamalla WIFI pois päältä kun
        # läppäri on verkossa telakan kautta.
        # Skripti otettu Arch Linuxin wikistä: https://wiki.archlinux.org/title/NetworkManager
        # Skriptin lokituksen näkee komennolla:
        #   journalctl -fu NetworkManager-dispatcher.service
        dispatcherScripts = [{
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
      };
      networking.useDHCP = lib.mkDefault true;
      networking.hostName = "dellxps13";

      # Määrittele avain jolla voidaan purkaa salaus (normaalisti voisi käyttää
      # openssh palvelun host avainta, mutta se vaatisi openssh palvelun käyttöönoton)
      age.identityPaths = [ "/home/jhakonen/.ssh/id_rsa" ];

      # Enable the KDE Plasma Desktop Environment.
      services.displayManager.sddm.enable = true;
      services.displayManager.sddm.wayland.enable = true;
      services.desktopManager.plasma6.enable = true;  # kommentoi pois hyprlandia varten

      # Konfiguroi verkkotulostimen tuki
      services.avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
      };
      services.printing.enable = true;

      hardware.bluetooth.enable = true;
      hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

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

      # Vamuuskopiointi
      #   Käynnistä:
      #     systemctl start restic-backups-jhakonen-oma.service
      #     systemctl start restic-backups-jhakonen-veli.service
      #   Snapshotit:
      #     sudo restic-jhakonen-oma snapshots
      #     sudo restic-jhakonen-veli snapshots
      my.services.restic.backups = let
        bConfig = {
          exclude = [
            ".cache"
            ".Trash*"
            ".local/share/Trash"
            ".local/share/baloo"
            ".steam"
            "Calibre"
            "Keepass"
            "OpenCloud"
            "Syncthing"
          ];
          paths = [
            "/home/jhakonen"
          ];
          checkOpts = [ "--read-data-subset" "10%" ];
        };
      in {
        jhakonen-oma = bConfig // {
          repository = "rclone:nas-oma:/backups/restic/dellxps13-jhakonen";
          timerConfig.OnCalendar = "01:00";
        };
        jhakonen-veli = bConfig // {
          repository = "rclone:nas-veli:/home/restic/dellxps13-jhakonen";
          timerConfig.OnCalendar = "Sat 02:00";
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
        brave
        cachix
        calibre
        cherry-studio
        chromium
        claude-code
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
        kdePackages.krecorder
        kdePackages.plasma-thunderbolt  # Asetusvälilehti thunderboltille (lisäksi services.hardware.bolt)
        kdePackages.qtwebsockets  # Tarvitaan Home Assistant plasmoidia varten
        kdePackages.kcalc
        kdePackages.signond  # Tarvitaan Nextcloud tilin lisäämiseen
        mcomix
        meld
        moonlight-qt
        mqttx
        nixos-rebuild-ng
        obsidian
        renameutils  # qmv
        sublime4
        super-productivity-latest
        syncthingtray-minimal
        teams-for-linux
        tidal-hifi
        trayscale
        zoom-us

        inputs.qjournalctl.packages.${pkgs.stdenv.system}.default
        inputs.zen-browser.packages.${pkgs.stdenv.system}.default
        #inputs.mypanel.packages.${pkgs.stdenv.system}.default

        pkgs-mistral-vibe.mistral-vibe
      ];

      fonts.packages = with pkgs; [
        cascadia-code
      ];

      services.flatpak.packages = [
        "app.grayjay.Grayjay"
        "com.github.tchx84.Flatseal"
        "io.github.mfat.sshpilot"
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

      programs.kde-pim = {
        enable = true;
        kontact = true;
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

    homeManager = {
      home.stateVersion = "23.05";
    };
  };

  den.aspects."jhakonen@dellxps13".homeManager = { config, pkgs, ... }: {
    imports = [
      inputs.agenix.homeManagerModules.age
      # inputs.jhhapanel.homeManagerModules.default
    ];

    # Add stuff for your user as you see fit:
    # programs.neovim.enable = true;
    home.packages = [
      (pkgs.callPackage "${inputs.agenix}/pkgs/agenix.nix" {})
      #pkgs.calibre
      pkgs.nixos-rebuild  # rebuildaus etäkoneelle
      pkgs.nix-index  # Nixpkgs pakettien sisällön etsiminen
    ];

    # Enable home-manager and git
    programs.home-manager.enable = true;

    # programs.jhhapanel = {
    #   enable = true;
    # };

    programs.ssh = {
      enable = true;
      matchBlocks = {
        "kota" = {
          user = "pi";
        };
        "nas" = {
          user = "valvoja";
          identityFile = [
            "~/.ssh/id_rsa"
          ];
        };
        "codeberg.org" = {
          user = "git";
        };
      };
    };

    accounts.email.accounts = catalog.emailAccounts;
    programs.thunderbird = {
      enable = true;
      package = pkgs.thunderbird;  # Thunderbird 115 paremmalla käyttöliittymällä
      profiles."${config.home.username}" = {
        isDefault = true;
        settings = {
          # Järjestä mailit oletuksena kaikissa kansioissa laskevasti (uusin ensimmäisenä)
          "mailnews.default_sort_order" = 2;
        };
      };
    };

    services.easyeffects = {
      enable = true;
    };

    # Nicely reload system units when changing configs
    systemd.user.startServices = "sd-switch";

    # https://nixos.wiki/wiki/Home_Manager#Usage_on_non-NixOS_Linux
    # targets.genericLinux.enable = true;

    # https://wiki.nixos.org/wiki/Default_applications
    # Tiedostotyypin näkee komennolla "file -i <tiedoston polku>"
    # Tiedostopääte mimetyypiksi, katso: /run/current-system/sw/share/mime/globs
    # xdg.mimeApps = {
    #   enable = true;
    #   defaultApplications = {
    #     "text/html" = "firefox.desktop";
    #     "text/markdown" = "sublime_text.desktop";
    #     "text/plain" = "org.gnome.TextEditor.desktop";
    #     "x-scheme-handler/about" = "firefox.desktop";
    #     "x-scheme-handler/element" = "Beeper.desktop";
    #     "x-scheme-handler/http" = "firefox.desktop";
    #     "x-scheme-handler/https" = "firefox.desktop";
    #     "x-scheme-handler/mailto" = "thunderbird.desktop";
    #     "x-scheme-handler/unknown" = "firefox.desktop";
    #   };
    # };

    # Ylikrjoita mime asetukset jos niitä tulee muokattua käsin, esim. Nemolla
    # muuttamalla tiedoston oletusohjelmaa
    # xdg.configFile."mimeapps.list".force = true;

    xdg.userDirs = {
      enable = true;
      desktop = "${config.home.homeDirectory}/Työpöytä";
      documents = "${config.home.homeDirectory}/Asiakirjat";
      download = "${config.home.homeDirectory}/Lataukset";
      music = "${config.home.homeDirectory}/Musiikki";
      pictures = "${config.home.homeDirectory}/Kuvat";
      publicShare = "${config.home.homeDirectory}/Julkinen";
      templates = "${config.home.homeDirectory}/Mallit";
      videos = "${config.home.homeDirectory}/Videot";
    };

    # gtk.theme = {
    #   package = pkgs.flat-remix-gtk;
    #   # Mahdolliset teemojen nimet löytää komennolla:
    #   #   ll $(nix eval --raw nixpkgs#flat-remix-gtk.outPath)/share/themes/
    #   name = "Flat-Remix-GTK-Yellow-Dark";
    # };
    # gtk.iconTheme = {
    #   package = pkgs.yaru-remix-theme;
    #   # Mahdolliset teemojen nimet löytää komennolla:
    #   #   ll $(nix eval --raw nixpkgs#yaru-remix-theme.outPath)/share/icons/
    #   name = "Yaru-remix-light";
    # };
  };

  den.aspects.kanto.nixos = {
    # Palvelun valvonta
    services.gatus.settings.endpoints = [{
      name = "Syncthing (dellxps13)";
      url = "http://${catalog.services.syncthing-dellxps13.host.hostName}:${toString catalog.services.syncthing-dellxps13.port}";
      conditions = [ "[STATUS] == 200" ];
    }];
  };
}
