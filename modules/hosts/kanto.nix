{ config, den, inputs, lib, ... }: let
  inherit (config) catalog;
in {
  imports = [ inputs.den.flakeModule ];

  den.hosts.x86_64-linux.kanto.users.jhakonen = {};
  den.hosts.x86_64-linux.kanto.users.root = {};

  den.aspects.kanto.includes = [
    den.aspects.nginx
    den.aspects.tailscale
  ];
  den.aspects.kanto.nixos = { config, modulesPath, pkgs, ... }: {
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

    # Ota flaket käyttöön
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    imports = [
      (modulesPath + "/installer/scan/not-detected.nix")
      inputs.agenix.nixosModules.default
    ];

    nixpkgs.config.allowUnfree = true;

    # Käytä systemd-boot EFI boot loaderia
    boot.extraModulePackages = [ ];
    boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ "kvm-intel" ];
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.systemd-boot.enable = true;

    fileSystems."/" = {
      device = "/dev/disk/by-uuid/485bf9d3-9db7-470f-b805-476a5bb95813";
      fsType = "ext4";
    };

    fileSystems."/boot" = {
      device = "/dev/disk/by-uuid/4674-FF6D";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };

    swapDevices = [];

    # Listaa paketit jotka ovat saatavilla PATH:lla
    environment.systemPackages = with pkgs; [];

    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    networking.useDHCP = lib.mkDefault true;
    networking.hostName = "kanto";

    # Ota Let's Encryptin sertifikaatti käyttöön
    security.acme.certs."jhakonen.com".extraDomainNames = [
      "*.jhakonen.com"
      "*.kanto.lan.jhakonen.com"
    ];

    # Näyttää salasana-kehotteen kun ohjelma tarvitsee root-oikeudet
    security.polkit.enable = true;


    # Salaisuudet
    age.secrets = {
      mosquitto-esphome-password.file = ../../agenix/mqtt-espuser-password.age;
    };

    # Valvonnan asetukset
    my.services.monitoring = {
      enable = true;
      acmeHost = "jhakonen.com";
      virtualHost = catalog.services.monit-kanto.public.domain;
    };

    # Tiedostojen synkkaus
    my.services.syncthing = {
      enable = true;
      gui-port = catalog.services.syncthing-kanto.port;
      user = "root";
      data-dir = "/root";
      settings = {
        devices = catalog.pickSyncthingDevices ["nas"];
        folders = {
          "Muistiinpanot" = {
            path = catalog.paths.syncthing.muistiinpanot;
            devices = [ "nas" ];
          };
          "Päiväkirja" = {
            path = catalog.paths.syncthing.paivakirja;
            devices = [ "nas" ];
          };
        };
      };
    };

    # Palvelun valvonta
    services.gatus.settings.endpoints = [{
      name = "Syncthing (kanto)";
      url = "http://${catalog.services.syncthing-kanto.host.hostName}:${toString catalog.services.syncthing-kanto.port}";
      conditions = [ "[STATUS] == 200" ];
    }];

    # Älä muuta ellei ole pakko, ei edes uudempaan versioon päivittäessä
    system.stateVersion = "24.05";
  };

  den.aspects.kanto.homeManager = {
    # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
    home.stateVersion = "24.05";
  };
}
