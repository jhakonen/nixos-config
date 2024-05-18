# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ config, pkgs, ... }:
let
  catalog = config.dep-inject.catalog;

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
      ../../roles/nixos/bt-mqtt-gateway.nix
      ../../roles/nixos/common-programs.nix
      ../../roles/nixos/gpio-shutdown.nix
      ../../roles/nixos/nix-cleanup.nix
      ../../roles/nixos/promtail.nix
      ../../roles/nixos/zigbee2mqtt.nix
      ../../roles/nixos/zsh.nix
    ];

  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;

  boot.blacklistedKernelModules = [
    "btbcm" "hci_uart"  # Poista sisäinen bluetooth sovitin pois käytöstä
                        # Lähde: https://plone.lucidsolutions.co.nz/hardware/raspberry-pi/3/disable-unwanted-raspbian-services
  ];

  networking.hostName = "kota-portti"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "Europe/Helsinki";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

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

  console = {
  #   font = "Lat2-Terminus16";
    keyMap = "fi";
  #   useXkbConfig = true; # use xkbOptions in tty.
  };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;


  

  # Configure keymap in X11
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;

  # Tarvitaan jotta bluetooth toimii, myös kun käytetään asusin usb bluetooth
  # mokkulaa, asentaa myös hcitool ohjelman
  hardware.bluetooth.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # # Varmuuskopiointi
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

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.jhakonen = {
    openssh.authorizedKeys.keys = [ id-rsa-public-key ];
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  };
  users.users.root = {
    openssh.authorizedKeys.keys = [ id-rsa-public-key ];
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
        ../../roles/home-manager/mqtt-client.nix
        ../../roles/home-manager/zsh.nix
      ];
      roles.mqtt-client.passwordFile = config.age.secrets.jhakonen-mosquitto-password.path;
      home.stateVersion = "23.05";
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [];

  # Asenna root ca certifikaatti, tarvitaan kun otetaan
  # yhteyttä *.jhakonen.com domaineihin SSL:n yli, esim. MQTT
  security.pki.certificateFiles = [ ../../data/root-ca.pem ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # Salaisuudet
  age.secrets = {
    jhakonen-mosquitto-password = {
      file = ../../secrets/mqtt-password.age;
      owner = "jhakonen";
    };
    rsyncbackup-password.file = ../../secrets/rsyncbackup-password.age;
  };

  # List services that you want to enable:
  services = {
    # Enable the OpenSSH daemon.
    openssh = {
      enable = true;
      settings = {
        # Vaadi SSH sisäänkirjautuminen käyttäen vain yksityistä avainta
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

  # Mounttaa config.txt saataville
  # fileSystems."/mnt/firmware" = {
  #   device = "/dev/disk/by-label/FIRMWARE";
  #   fsType = "vfat";
  # };
}
