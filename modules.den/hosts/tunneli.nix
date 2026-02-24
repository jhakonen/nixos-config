{ inputs, den, ... }:
{
  imports = [ inputs.den.flakeModule ];

  den.hosts.x86_64-linux.tunneli.users.jhakonen = {};
  den.hosts.x86_64-linux.tunneli.users.root = {};

  den.aspects.tunneli = {
    includes = [
      den.aspects.nginx
      den.aspects.tailscale
    ];

    nixos = { lib, modulesPath, ... }: {
      imports = [
        (modulesPath + "/profiles/qemu-guest.nix")
        inputs.agenix.nixosModules.default
      ];

      nix.settings.experimental-features = [ "nix-command" "flakes" ];
      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

      boot.extraModulePackages = [ ];
      boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ ];
      boot.loader.grub.enable = true;
      boot.loader.grub.device = "/dev/sda";

      fileSystems."/" = {
        device = "/dev/disk/by-uuid/68a09a29-8de0-444b-a74f-b3b4a11abaa7";
        fsType = "ext4";
      };

      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/87d872cd-936a-408b-9256-9ba179a98c2b";
        fsType = "ext4";
      };

      swapDevices =
        [ { device = "/dev/disk/by-uuid/9c394122-bc7b-45e6-9796-f7c7a132c767"; }
        ];

      networking.hostName = "tunneli";
      networking.useDHCP = true;


      # Ota Let's Encryptin sertifikaatti käyttöön
      security.acme.certs."jhakonen.com".extraDomainNames = [
        "*.jhakonen.com"
        "*.tunneli.public.jhakonen.com"
      ];

      services.openssh.enable = true;

      services.nginx = {
        enable = true;
        clientMaxBodySize = "0";
        proxyTimeout = "10h";
        recommendedGzipSettings = true;
        recommendedOptimisation = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
      };

      # Älä muuta ellei ole pakko, ei edes uudempaan versioon päivittäessä
      system.stateVersion = "25.05";

      users.users.jhakonen = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
      };

    };

    homeManager = {
      home.stateVersion = "25.05";
    };
  };
}
