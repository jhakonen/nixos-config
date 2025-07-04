{ inputs, self, ... }:
{
  flake.modules.nixos.kanto = { config, pkgs, ... }: let
    inherit (self) catalog;
  in {
    # Ota flaket käyttöön
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    imports = [
      inputs.agenix.nixosModules.default
      inputs.home-manager.nixosModules.home-manager

      self.modules.nixos.service-dashy
      self.modules.nixos.service-monitoring
      self.modules.nixos.service-mqttwarn
      self.modules.nixos.service-rsync
      self.modules.nixos.service-syncthing

      self.modules.nixos.calibre
      self.modules.nixos.common
      self.modules.nixos.dashy
      self.modules.nixos.freshrss
      self.modules.nixos.grafana
      self.modules.nixos.hoarder
      self.modules.nixos.home-assistant
      self.modules.nixos.immich
      self.modules.nixos.influxdb
      self.modules.nixos.koti
      self.modules.nixos.mqtt-server
      self.modules.nixos.mqttwarn
      self.modules.nixos.netdata-child
      self.modules.nixos.nextcloud
      self.modules.nixos.nix-cleanup
      self.modules.nixos.node-red
      self.modules.nixos.paperless
      self.modules.nixos.telegraf
      self.modules.nixos.tvheadend
      self.modules.nixos.zsh
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

    # Anna nginxille pääsy let's encrypt serifikaattiin
    users.users.nginx.extraGroups = [ "acme" ];

    # Listaa paketit jotka ovat saatavilla PATH:lla
    environment.systemPackages = with pkgs; [];

    security = {
      # Ota Let's Encryptin sertifikaatti käyttöön
      acme = {
        acceptTerms = true;
        defaults = {
          email = catalog.acmeEmail;
          dnsProvider = "joker";
          credentialsFile = config.age.secrets.acme-joker-credentials.path;
        };
        certs."jhakonen.com".extraDomainNames = [
          "*.jhakonen.com"
          "*.kanto.lan.jhakonen.com"
        ];
      };
      # Näyttää salasana-kehotteen kun ohjelma tarvitsee root-oikeudet
      polkit.enable = true;
    };

    # Salaisuudet
    age.secrets = {
      acme-joker-credentials.file = ../../../agenix/acme-joker-credentials.age;
      jhakonen-rsyncbackup-password = {
        file = ../../../agenix/rsyncbackup-password.age;
        owner = "jhakonen";
      };
      mosquitto-password.file = ../../../agenix/mqtt-password.age;
      mosquitto-esphome-password.file = ../../../agenix/mqtt-espuser-password.age;
      rsyncbackup-password.file = ../../../agenix/rsyncbackup-password.age;
      wireless-password.file = ../../../agenix/wireless-password.age;
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
  };

  flake.modules.homeManager.kanto = {
    # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
    home.stateVersion = "24.05";
  };
}
