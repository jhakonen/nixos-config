{ config, pkgs, ... }:
let
  inherit (config.dep-inject) catalog private;

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
    ../../modules
    ../../roles/nixos/calibre.nix
    ../../roles/nixos/common-programs.nix
    ../../roles/nixos/dashy.nix
    ../../roles/nixos/freshrss.nix
    ../../roles/nixos/grafana.nix
    ../../roles/nixos/hoarder.nix
    ../../roles/nixos/home-assistant.nix
    ../../roles/nixos/huginn.nix
    ../../roles/nixos/influxdb.nix
    ../../roles/nixos/koti.nix
    ../../roles/nixos/mosquitto.nix
    ../../roles/nixos/mqttwarn.nix
    ../../roles/nixos/netdata-child.nix
    ../../roles/nixos/nextcloud.nix
    ../../roles/nixos/nix-cleanup.nix
    ../../roles/nixos/node-red.nix
    ../../roles/nixos/paperless.nix
    ../../roles/nixos/telegraf.nix
    ../../roles/nixos/tvheadend.nix
    ../../roles/nixos/zsh.nix
  ];

  nixpkgs.config.allowUnfree = true;

  # Käytä systemd-boot EFI boot loaderia
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "kanto"; # Define your hostname.
  # Wifi tuki käyttäen wpa_supplicant palvelua
  networking.wireless = {
    enable = true;
    secretsFile = config.age.secrets.wireless-password.path;
    networks = {
      Hyttysverkko.pskRaw = "ext:HYTTYSVERKKO_PASSWORD";
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

  # Ota Let's Encryptin sertifikaatti käyttöön
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = private.catalog.acmeEmail;
      dnsProvider = "joker";
      credentialsFile = config.age.secrets.acme-joker-credentials.path;
    };
    certs."jhakonen.com".extraDomainNames = [
      "*.jhakonen.com"
      "*.kanto.lan.jhakonen.com"
    ];
  };

  # Salaisuudet
  age.secrets = {
    acme-joker-credentials.file = private.secret-files.acme-joker-credentials;
    jhakonen-mosquitto-password = {
      file = private.secret-files.mqtt-password;
      owner = "jhakonen";
    };
    jhakonen-rsyncbackup-password = {
      file = private.secret-files.rsyncbackup-password;
      owner = "jhakonen";
    };
    mosquitto-password.file = private.secret-files.mqtt-password;
    mosquitto-esphome-password.file = private.secret-files.mqtt-espuser-password;
    rsyncbackup-password.file = private.secret-files.rsyncbackup-password;
    wireless-password.file = private.secret-files.wireless-password;
  };

  services = {
    nginx.virtualHosts."default" = {
      default = true;
      # Vastaa määrittelemättömään domainiin tai porttiin 403 virheellä
      locations."/".extraConfig = ''
        deny all;
      '';
    };

    openssh = {
      enable = true;
      settings = {
        # Vaadi SSH sisäänkirjautuminen käyttäen vain yksityistä avainta
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };
  };

  # Valvonnan asetukset
  my.services.monitoring = {
    enable = true;
    acmeHost = "jhakonen.com";
    virtualHost = catalog.services.monit-kanto.public.domain;
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

  # Tiedostojen synkkaus
  my.services.syncthing = {
    enable = true;
    gui-port = catalog.services.syncthing-kanto.port;
    user = "root";
    data-dir = "/root";
    settings = {
      devices = catalog.pickSyncthingDevices ["nas"];
    };
  };

  # Palomuurin asetukset
  networking.firewall.allowedTCPPorts = [ 80 443 ];  # nginx

  # Älä muuta ellei ole pakko, ei edes uudempaan versioon päivittäessä
  system.stateVersion = "24.05";
}
