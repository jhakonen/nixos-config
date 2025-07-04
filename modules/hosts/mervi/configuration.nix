# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{ inputs, self, ... }:
{
  flake.modules.nixos.mervi = { config, pkgs, ... }: let
    inherit (self) catalog;
  in {
    # Ota flaket käyttöön
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    imports = [
      inputs.agenix.nixosModules.default
      inputs.home-manager.nixosModules.home-manager

      self.modules.nixos.service-rsync
      self.modules.nixos.service-monitoring
      self.modules.nixos.service-syncthing

      self.modules.nixos.common
      self.modules.nixos.gamepads
      self.modules.nixos.koti
      self.modules.nixos.nginx
      self.modules.nixos.nix-cleanup
      self.modules.nixos.sunshine
    ];

    # Bootloader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    # Hallitse verkkoyhteyttä NetworkManagerilla
    networking.networkmanager.enable = true;

    # Ota Wake-on-Lan (WoL) käyttöön
    networking.interfaces."enp3s0".wakeOnLan.enable = true;

     # Enable the X11 windowing system.
    #services.xserver.enable = true;

    # Enable the KDE Plasma Desktop Environment.
    services.displayManager.sddm.enable = true;
    services.displayManager.sddm.wayland.enable = true;
    services.desktopManager.plasma6.enable = true;

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
        devices = catalog.pickSyncthingDevices ["dellxps13" "nas"];
        folders = {
          "Keepass" = {
            path = "/home/jhakonen/Keepass";
            devices = [ "dellxps13" "nas" ];
          };
        };
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
    security.acme.certs."mervi.lan.jhakonen.com".extraDomainNames = [
      "*.mervi.lan.jhakonen.com"
    ];

    # Salaisuudet
    age.secrets = {
      jhakonen-rsyncbackup-password = {
        file = ../../../agenix/rsyncbackup-password.age;
        owner = "jhakonen";
      };
      mosquitto-password.file = ../../../agenix/mqtt-password.age;
      rsyncbackup-password.file = ../../../agenix/rsyncbackup-password.age;
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

    networking.firewall.allowedUDPPorts = [
      40000  # WoL portti, ei pakollinen mutta tarpeellinen WoLin testaukseen ngrepillä
    ];

    system.stateVersion = "23.05";
  };

  flake.modules.homeManager.mervi = {
    # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
    home.stateVersion = "23.05";
  };
}
