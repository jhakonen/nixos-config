{ inputs, den, ... }:
{
  den.hosts.x86_64-linux.raami.users.jhakonen = {};
  den.hosts.x86_64-linux.raami.users.root = {};

  den.aspects.raami = {
    includes = [
      den.aspects.ai-tools
      den.aspects.beeper
      den.aspects.firefox
      den.aspects.flatpak
      den.aspects.git
      den.aspects.koti
      den.aspects.sonos
      den.aspects.tailscale
      den.aspects.virtualization
    ];

    nixos = { config, lib, modulesPath, pkgs, ... }: {
      nix.package = pkgs.lix;
      # Ota flaket käyttöön
      nix.settings.experimental-features = [ "nix-command" "flakes" ];

      nix.settings.cores = 8;
      nix.settings.max-jobs = 8;

      nixpkgs = {
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [
            "electron-38.8.4" # cherry-studio
          ];
          problems.handlers = {
            sublimetext4.broken = "ignore";
          };
        };
        hostPlatform = "x86_64-linux";
      };

      imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
        inputs.nixos-hardware.nixosModules.framework-intel-core-ultra-series3
      ];

      # Bootloader.
      boot.extraModulePackages = [ ];
      boot.kernelPackages = pkgs.linuxPackages_latest;

      boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" ];
      boot.initrd.kernelModules = [ ];
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
      boot.kernelModules = [ "kvm-intel" ];

      boot.initrd.luks.devices."luks-e74395fd-4716-4b8b-ab65-70255933ece8".device = "/dev/disk/by-uuid/e74395fd-4716-4b8b-ab65-70255933ece8";
      boot.initrd.luks.devices."luks-38136262-80c8-4d71-989e-9f3312352aaf".device = "/dev/disk/by-uuid/38136262-80c8-4d71-989e-9f3312352aaf";

      fileSystems."/" = {
        device = "/dev/mapper/luks-38136262-80c8-4d71-989e-9f3312352aaf";
        fsType = "ext4";
      };

      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/98A8-FBB6";
        fsType = "vfat";
        options = [ "fmask=0077" "dmask=0077" ];
      };

      swapDevices = [
        { device = "/dev/mapper/luks-e74395fd-4716-4b8b-ab65-70255933ece8"; }
      ];

      networking.networkmanager = {
        # Hallitse verkkoyhteyttä NetworkManagerilla
        enable = true;

        # Uudempi networkmanagerin versio (1.56.0 tai uudempi) joka ei aiheuta virhettä kun yritää
        # yhdistää langattomaan verkkoon.
        # Komento:
        #   $ nmcli device wifi connect <SSID> password <salasana>
        #   > 802-11-wireless-security.key-mgmt: property is missing
        # Raportoitu bugi:
        #   https://gitlab.freedesktop.org/NetworkManager/NetworkManager/-/issues/1688
        package = pkgs.unstable.networkmanager;

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
      networking.hostName = "raami";

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
      hardware.cpu.intel.npu.enable = true;
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
        # Use the WirePlumber session manager
        #wireplumber.enable = true;
      };

      # Vamuuskopiointi
      #   Käynnistä:
      #     systemctl start restic-backups-jhakonen-oma.service
      #     systemctl start restic-backups-jhakonen-veli.service
      #   Snapshotit:
      #     sudo restic-jhakonen-oma snapshots
      #     sudo restic-jhakonen-veli snapshots
      # my.services.restic.backups = let
      #   bConfig = {
      #     exclude = [
      #       ".cache"
      #       ".Trash*"
      #       ".local/share/Trash"
      #       ".local/share/baloo"
      #       ".steam"
      #       "Calibre"
      #       "Keepass"
      #       "Syncthing"
      #       "tmp"
      #     ];
      #     paths = [
      #       "/home/jhakonen"
      #     ];
      #     # TODO: Ota lukon avaaminen käyttöön jos tulee vielä sen kanssa ongelmia
      #     #       vaikka inhibitsSleep on päällä.
      #     # backupPrepareCommand = "${lib.getExe pkgs.restic} unlock";
      #     checkOpts = [ "--read-data-subset" "10%" ];
      #     inhibitsSleep = true;
      #     timerConfig.Persistent = true;
      #   };
      # in {
      #   jhakonen-oma = bConfig // {
      #     repository = "rclone:nas-oma:/backups/restic/raami-jhakonen";
      #     timerConfig.OnCalendar = "01:00";
      #   };
      #   jhakonen-veli = bConfig // {
      #     repository = "rclone:nas-veli:/home/restic/raami-jhakonen";
      #     timerConfig.OnCalendar = "Sat 02:00";
      #   };
      # };

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
        gui-port = config.catalog.services.syncthing-raami.port;
        settings = {
          devices = config.catalog.pickSyncthingDevices ["mervi" "nas"];
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

      home-manager.backupFileExtension = "hm-backup";

      environment.systemPackages = with pkgs; [
        agenix-cli
        aspell
        aspellDicts.en
        aspellDicts.fi
        brave
        cachix
        devenv
        discord
        easyeffects
        exfatprogs  # kdePackages.partitionmanager tarvitsee exfat tukea varten
        git-crypt
        immich-cli
        keepassxc
        libreoffice
        livecaptions
        kdePackages.kdeconnect-kde
        kdePackages.kmahjongg
        kdePackages.kolourpaint
        kdePackages.krecorder
        kdePackages.kcalc
        kdePackages.partitionmanager
        meld
        moonlight-qt
        mqttx
        nix-index  # Nixpkgs pakettien sisällön etsiminen
        nixos-rebuild-ng
        obsidian
        renameutils  # qmv
        sublime4-dev # sublime4 -paketissa plugin host 3.8 kaatuu 20.9.2026
        syncthingtray-minimal
        trayscale

        unstable.calibre
        unstable.npins  # 0.4.0 oci container tukea varten
        nix-prefetch-docker  # npins riippuvuus
      ];

      fonts.packages = with pkgs; [
        cascadia-code
      ];

      services.flatpak.packages = [
        "app.grayjay.Grayjay"
        "com.github.tchx84.Flatseal"
        "org.gnome.Papers"
        "org.gnome.Showtime"
      ];

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
      # networking.firewall.allowedTCPPorts = [];
      # networking.firewall.allowedUDPPorts = [ ... ];

      networking.firewall.allowedTCPPortRanges = [
        { from = 1714; to = 1764; }  # KDE Connect
      ];
      networking.firewall.allowedUDPPortRanges = [
        { from = 1714; to = 1764; }  # KDE Connect
      ];

      # Or disable the firewall altogether.
      # networking.firewall.enable = false;

      system.stateVersion = "26.05";

      services.fwupd = {
        enable = true;
        extraRemotes = [ "lvfs-testing" ];
        uefiCapsuleSettings.DisableCapsuleUpdateOnDisk = true;
      };

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
    };

    provides.to-users.homeManager = {
      home.stateVersion = "26.05";
    };

    provides.jhakonen.homeManager = { config, pkgs, ... }: {
      # imports = [];
      # Enable home-manager and git
      programs.home-manager.enable = true;

      programs.ssh = {
        enable = true;
        settings = {
          "nas" = {
            User = "valvoja";
            IdentityFile = [
              "~/.ssh/id_rsa"
            ];
          };
          "codeberg.org" = {
            User = "git";
          };
        };
      };

      accounts.email.accounts = config.catalog.emailAccounts;
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
        setSessionVariables = true;
      };
    };
  };

#   den.aspects.kanto.nixos = { config, ... }: {
#     # Palvelun valvonta
#     services.gatus.settings.endpoints = [{
#       name = "Syncthing (dellxps13)";
#       url = "http://${config.catalog.services.syncthing-dellxps13.host.hostName}:${toString config.catalog.services.syncthing-dellxps13.port}";
#       conditions = [ "[STATUS] == 200" ];
#     }];
#   };
}
