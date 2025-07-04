{ inputs, self, ... }:
{
  flake.modules.nixos.toukka = { config, lib, pkgs, ... }: let
    inherit (self) catalog;
  in {
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
      inputs.agenix.nixosModules.default
      inputs.home-manager.nixosModules.home-manager

      self.modules.nixos.service-rsync
      self.modules.nixos.service-monitoring

      self.modules.nixos.common
      self.modules.nixos.nix-cleanup
      self.modules.nixos.zigbee2mqtt
    ];

    # Käytä systemd-boot EFI boot loaderia
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = false;

    # Käytä rpi4 kohtaista kerneliä
    boot.kernelPackages = pkgs.linuxPackages_rpi4;
    # (import (builtins.fetchTarball {
    #   url = https://gitlab.com/vriska/nix-rpi5/-/archive/main.tar.gz;
    #   sha256 = "12110c0sbycpr5sm0sqyb76aq214s2lyc0a5yiyjkjhrabghgdcb";
    # })).legacyPackages.aarch64-linux.linuxPackages_rpi5;

    # Laitteen nimi
    networking.hostName = "toukka";

    # Wifi tuki käyttäen wpa_supplicant palvelua
    networking.wireless = {
      enable = true;
      secretsFile = "/root/wireless.env";
      networks = {
        POSEIDON_5G.pskRaw = "ext:POSEIDON_5G_PASSWORD";
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

    # Anna nginxille pääsy let's encrypt serifikaattiin
    users.users.nginx.extraGroups = [ "acme" ];

    security = {
      # Ota Let's Encryptin sertifikaatti käyttöön
      acme = {
        acceptTerms = true;
        defaults = {
          email = catalog.acmeEmail;
          dnsProvider = "joker";
          credentialsFile = config.age.secrets.acme-joker-credentials.path;
        };
        certs."toukka.lan.jhakonen.com".extraDomainNames = [ "*.toukka.lan.jhakonen.com" ];
      };
      # Näyttää salasana-kehotteen kun ohjelma tarvitsee root-oikeudet
      polkit.enable = true;
    };

    # Salaisuudet
    age.secrets = {
      acme-joker-credentials.file = ../../../agenix/acme-joker-credentials.age;
      mosquitto-password.file = ../../../agenix/mqtt-password.age;
      rsyncbackup-password.file = ../../../agenix/rsyncbackup-password.age;
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

    # Palomuurin asetukset
    networking.firewall.allowedTCPPorts = [ 80 443 ];  # nginx

    # Älä muuta ellei ole pakko, ei edes uudempaan versioon päivittäessä
    system.stateVersion = "23.11";
  };

  flake.modules.homeManager.toukka = {
    # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
    home.stateVersion = "23.11";
  };
}
