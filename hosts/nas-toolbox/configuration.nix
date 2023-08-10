# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, agenix, home-manager, ... }:
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
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../modules
      ../../roles/nixos/backup.nix
      ../../roles/nixos/dashy.nix
      ../../roles/nixos/grafana.nix
      ../../roles/nixos/home-assistant.nix
      ../../roles/nixos/huginn.nix
      ../../roles/nixos/influxdb.nix
      ../../roles/nixos/mosquitto.nix
      ../../roles/nixos/mqttwarn.nix
      ../../roles/nixos/nitter.nix
      ../../roles/nixos/node-red.nix
      ../../roles/nixos/paperless.nix
      ../../roles/nixos/telegraf.nix
      ../../roles/nixos/vaultwarden.nix
      home-manager.nixosModules.default
    ];

  # Bootloader.
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
    useOSProber = true;
  };

  networking.hostName = "nas-toolbox";

  # Enable networking
  networking.networkmanager.enable = true;

  # Salli docker-konteista pääsy isäntäkoneelle
  # networking.firewall.trustedInterfaces = [ "docker0" ];
  # virtualisation.docker.enable = true;
  # virtualisation.oci-containers.backend = "docker";

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

  # Configure console keymap
  console.keyMap = "fi";

  users = {
    # Aseta käytettävä komentotulkki
    # Huomaa: komentotulkki pitää olla environment.shells listassa
    defaultUserShell = pkgs.zsh;

    users = {
      jhakonen = {
        openssh.authorizedKeys.keys = [ id-rsa-public-key ];
        isNormalUser = true;
        description = "Janne Hakonen";
        extraGroups = [
          # "docker"
          "networkmanager"
          "wheel"
        ];
        packages = with pkgs; [];
      };
      root = {
        openssh.authorizedKeys.keys = [ id-rsa-public-key ];
      };
    };
  };
  home-manager.users = {
    root = {
      home.stateVersion = "23.05";
      programs.ssh.enable = true;
    };
    jhakonen = { ... }: {
      imports = [
        ../../roles/home-manager/git.nix
        ../../roles/home-manager/neofetch.nix
        ../../roles/home-manager/zsh.nix
      ];
      home.stateVersion = "23.05";
      roles.git.githubIdentityFile = config.age.secrets.github-id-rsa.path;
    };
  };

  environment = {
    # Lisää ZSH valittavien komentotulkkien listaan 
    shells = [ pkgs.zsh ];

    # List packages installed in system profile. To search, run:
    # $ nix search wget
    systemPackages = [
      # Nixpkgs
      pkgs.btop
      pkgs.sqlite-interactive # sqlite3 vaultwardenin tietokannan tutkimiseen
      pkgs.git
      pkgs.inetutils  # telnet

      # Flaket
      agenix.packages."x86_64-linux".default
    ];
  };

  # Estä `inetutils` pakettia korvaamasta `nettools`
  # paketin ohjelmia `ifconfig`, `hostname` ja `dnsdomainname`
  nixpkgs.config.packageOverrides = pkgs: {
    nettools = pkgs.hiPrio pkgs.nettools;
  };

  # Asenna root ca certifikaatti, tarvitaan kun otetaan
  # yhteyttä *.jhakonen.com domaineihin SSL:n yli, esim. MQTT
  security.pki.certificateFiles = [ ../../data/root-ca.pem ];

  # Salaisuudet
  age.secrets = {
    github-id-rsa = {
      file = ../../secrets/github-id-rsa.age;
      owner = "jhakonen";
    };
  };

  # Tämä vaaditaan kun zsh on lisätty environment.shells listalle
  programs.zsh.enable = true;

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

    # Ota häntäverkko käyttöön, vaatii lisäksi komennon suorittamisen:
    #   sudo tailscale up
    tailscale.enable = true;

    # Configure keymap in X11
    xserver = {
      layout = "fi";
      xkbVariant = "nodeadkeys";
    };
  };


  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
