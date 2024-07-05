{ config, pkgs, ... }:
let
  inherit (config.dep-inject) catalog nix-rpi5 private;

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

  imports = [
    ./hardware-configuration.nix
  ];

  # Käytä systemd-boot EFI boot loaderia
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "kanto"; # Define your hostname.
  # Wifi tuki käyttäen wpa_supplicant palvelua
  networking.wireless = {
    enable = true;
    environmentFile = "/root/wireless.env";
    networks = {
      POSEIDON_5G.psk = "@POSEIDON_5G_PASSWORD@";
    };
  };

  # Aika-alueen asetus
  time.timeZone = "Europe/Helsinki";

  # Määrittele kieliasetukset
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

  console.keyMap = "fi";

  users.users = {
    jhakonen = {
      isNormalUser = true;
      description = "Janne Hakonen";
      extraGroups = [ "networkmanager" "wheel" ];
      packages = with pkgs; [];
      openssh.authorizedKeys.keys = [ id-rsa-public-key ];
    };
    root = {
      openssh.authorizedKeys.keys = [ id-rsa-public-key ];
    };
  };

  home-manager.users = {
    jhakonen = {
      imports = [
        # ../../roles/home-manager/mqtt-client.nix
        ../../roles/home-manager/zsh.nix
      ];
      # roles.mqtt-client.passwordFile = config.age.secrets.jhakonen-mosquitto-password.path;
      home.stateVersion = "24.05";
    };
    root = {
      imports = [
        ../../roles/home-manager/zsh.nix
      ];
      home.stateVersion = "24.05";
    };
  };

  # Listaa paketit jotka ovat saatavilla PATH:lla
  environment.systemPackages = with pkgs; [];

  services = {
    openssh = {
      enable = true;
      settings = {
        # Vaadi SSH sisäänkirjautuminen käyttäen vain yksityistä avainta
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };
  };

  system.stateVersion = "24.05"; # Did you read the comment?
}
