{ inputs, den, ... }:
{
  imports = [ inputs.den.flakeModule ];

  den.hosts.x86_64-linux.nassuvm.users.jhakonen = {};
  den.hosts.x86_64-linux.nassuvm.users.root = {};

  den.aspects.nassuvm = {
    includes = [
      den.aspects.nginx
      den.aspects.tailscale
    ];

    nixos = { lib, modulesPath, pkgs, ... }: {
      imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

      nix.settings.experimental-features = [ "nix-command" "flakes" ];
      nixpkgs.hostPlatform = "x86_64-linux";

      boot.extraModulePackages = [ ];
      boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ ];
      boot.loader.grub.enable = true;
      boot.loader.grub.device = "/dev/sda";
      boot.loader.grub.useOSProber = true;

      fileSystems."/" = {
        device = "/dev/disk/by-uuid/0298928a-d9a3-4362-9b46-9579272964c8";
        fsType = "ext4";
      };

      swapDevices = [];

      networking.hostName = "nassuvm";
      networking.networkmanager.enable = true;

      services.xserver.enable = true;
      services.xserver.displayManager.lightdm.enable = true;
      services.xserver.desktopManager.xfce.enable = true;

      services.pulseaudio.enable = false;
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
      };

      nixpkgs.config.allowUnfree = true;

      environment.systemPackages = with pkgs; [
        firefox
        simplescreenrecorder
      ];

      # Ota Let's Encryptin sertifikaatti käyttöön
      security.acme.certs."nassuvm.lan.jhakonen.com".extraDomainNames = [
        "*.nassuvm.lan.jhakonen.com"
      ];

      system.stateVersion = "23.05";

      virtualisation.hypervGuest.enable = true;
    };

    homeManager = {
      # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
      home.stateVersion = "24.05";
    };
  };
}
