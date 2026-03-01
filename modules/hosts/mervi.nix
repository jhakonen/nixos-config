{ config, inputs, den, ... }: let
  inherit (config) catalog;
in {
  imports = [ inputs.den.flakeModule ];

  den.hosts.x86_64-linux.mervi.users.jhakonen = {};
  den.hosts.x86_64-linux.mervi.users.root = {};

  den.aspects.mervi = {
    includes = [
      den.aspects.koti
      den.aspects.nginx
    ];

    nixos = { config, lib, modulesPath, pkgs, ... }: {
      imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

      # Ota flaket käyttöön
      nix.settings.experimental-features = [ "nix-command" "flakes" ];

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

      boot.extraModulePackages = [ ];
      boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
      boot.initrd.kernelModules = [ ];
      boot.loader.efi.canTouchEfiVariables = true;
      boot.loader.systemd-boot.enable = true;
      boot.kernelModules = [ "kvm-amd" ];

      hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

      # Tiedostojärjestelmät
      fileSystems."/" = {
        device = "/dev/disk/by-uuid/4621327e-c6a3-4e8b-9039-292c02543c55";
        fsType = "ext4";
      };
      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/68E6-1462";
        fsType = "vfat";
      };
      fileSystems."/data" = {
        device = "/dev/disk/by-label/DATA";
        fsType = "ext4";
      };
      swapDevices = [];

      # Hallitse verkkoyhteyttä NetworkManagerilla
      networking.networkmanager.enable = true;
      networking.useDHCP = lib.mkDefault true;
      networking.hostName = "mervi";

      # Ota Wake-on-Lan (WoL) käyttöön
      networking.interfaces."enp3s0".wakeOnLan.enable = true;

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

      programs.gamemode.enable = true;
      programs.kdeconnect.enable = true;
      programs.steam.enable = true;
      programs.zsh.shellAliases = {
        # Kokeile ottaako kone vastaan WoL paketteja
        wol-listen = "sudo ngrep '\\xff{6}(.{6})\\1{15}' -x port 40000";
      };

      # List services that you want to enable:

      services.flatpak.enable = true;

      networking.firewall.allowedUDPPorts = [
        40000  # WoL portti, ei pakollinen mutta tarpeellinen WoLin testaukseen ngrepillä
      ];

      system.stateVersion = "23.05";
    };

    homeManager = {
      # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
      home.stateVersion = "23.05";
    };
  };
}
