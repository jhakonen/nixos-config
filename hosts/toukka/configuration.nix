{ config, lib, pkgs, ... }:
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

  nixpkgs.overlays = [
    (final: prev: {
      linux-firmware = prev.linux-firmware.overrideAttrs {
        # Ota firmisten pakkaus pois päältä. Jostain syystä Asusin BT mokkulan
        # ajuri ei löydä firmware tiedostoa rtl_bt/rtl8761bu_fw.bin jos se on
        # pakattu. Ehkä syynä on vanha kernelin versio johon rpi5 tuki
        # perustuu?
        compressFirmware = false;
      };
    })
  ];

  imports = [
    ./hardware-configuration.nix
    ../../modules
    ../../roles/nixos/bt-mqtt-gateway.nix
    ../../roles/nixos/common-programs.nix
    ../../roles/nixos/nix-cleanup.nix
    ../../roles/nixos/zigbee2mqtt.nix
    ../../roles/nixos/zsh.nix
  ];

  # Käytä systemd-boot EFI boot loaderia
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  # Käytä rpi5 kohtaista kerneliä
  boot.kernelPackages = nix-rpi5.legacyPackages.aarch64-linux.linuxPackages_rpi5;
  # (import (builtins.fetchTarball {
  #   url = https://gitlab.com/vriska/nix-rpi5/-/archive/main.tar.gz;
  #   sha256 = "12110c0sbycpr5sm0sqyb76aq214s2lyc0a5yiyjkjhrabghgdcb";
  # })).legacyPackages.aarch64-linux.linuxPackages_rpi5;

  # Laitteen nimi
  networking.hostName = "toukka";

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

  # Tarvitaan jotta bluetooth toimii, myös kun käytetään asusin usb bluetooth
  # mokkulaa, asentaa myös hcitool ohjelman
  hardware.bluetooth.enable = true;

  # Valvonnan asetukset
  my.services.monitoring = {
    enable = true;
    acmeHost = "toukka.lan.jhakonen.com";
    virtualHost = catalog.services.monit-toukka.public.domain;
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

  users.users = {
    jhakonen = {
      openssh.authorizedKeys.keys = [ id-rsa-public-key ];
      isNormalUser = true;
      extraGroups = [ "wheel" ]; # Salli sudon käyttö
    };

    # Anna nginxille pääsy let's encrypt serifikaattiin
    nginx.extraGroups = [ "acme" ];

    root = {
      openssh.authorizedKeys.keys = [ id-rsa-public-key ];
    };
  };

  home-manager.users = {
    jhakonen = {
      imports = [
        ../../roles/home-manager/mqtt-client.nix
        ../../roles/home-manager/zsh.nix
      ];
      roles.mqtt-client.passwordFile = config.age.secrets.jhakonen-mosquitto-password.path;
      home.stateVersion = "23.11";
    };
    root = {
      imports = [
        ../../roles/home-manager/zsh.nix
      ];
      home.stateVersion = "23.11";
    };
  };

  # Ota Let's Encryptin sertifikaatti käyttöön
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = private.catalog.acmeEmail;
      dnsProvider = "joker";
      credentialsFile = config.age.secrets.acme-joker-credentials.path;
    };
    certs."toukka.lan.jhakonen.com".extraDomainNames = [ "*.toukka.lan.jhakonen.com" ];
  };

  # Salaisuudet
  age.secrets = {
    acme-joker-credentials.file = private.secret-files.acme-joker-credentials;
    jhakonen-mosquitto-password = {
      file = private.secret-files.mqtt-password;
      owner = "jhakonen";
    };
    mosquitto-password.file = private.secret-files.mqtt-password;
    rsyncbackup-password.file = private.secret-files.rsyncbackup-password;
  };

  # SSH palvelimen asetukset
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";

  # Palomuurin asetukset
  networking.firewall.allowedTCPPorts = [ 80 443 ];  # nginx

  # Älä muuta ellei ole pakko, ei edes uudempaan versioon päivittäessä
  system.stateVersion = "23.11";
}
