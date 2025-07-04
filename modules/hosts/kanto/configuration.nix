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
      self.modules.nixos.nginx
      self.modules.nixos.nix-cleanup
      self.modules.nixos.node-red
      self.modules.nixos.paperless
      self.modules.nixos.telegraf
      self.modules.nixos.tvheadend
    ];

    nixpkgs.config.allowUnfree = true;

    # Käytä systemd-boot EFI boot loaderia
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    # Listaa paketit jotka ovat saatavilla PATH:lla
    environment.systemPackages = with pkgs; [];

    # Ota Let's Encryptin sertifikaatti käyttöön
    security.acme.certs."jhakonen.com".extraDomainNames = [
      "*.jhakonen.com"
      "*.kanto.lan.jhakonen.com"
    ];

    # Näyttää salasana-kehotteen kun ohjelma tarvitsee root-oikeudet
    security.polkit.enable = true;


    # Salaisuudet
    age.secrets = {
      jhakonen-rsyncbackup-password = {
        file = ../../../agenix/rsyncbackup-password.age;
        owner = "jhakonen";
      };
      mosquitto-password.file = ../../../agenix/mqtt-password.age;
      mosquitto-esphome-password.file = ../../../agenix/mqtt-espuser-password.age;
      rsyncbackup-password.file = ../../../agenix/rsyncbackup-password.age;
    };

    services.openssh = {
      enable = true;
      settings = {
        # Vaadi SSH sisäänkirjautuminen käyttäen vain yksityistä avainta
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
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

    # Älä muuta ellei ole pakko, ei edes uudempaan versioon päivittäessä
    system.stateVersion = "24.05";
  };

  flake.modules.homeManager.kanto = {
    # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
    home.stateVersion = "24.05";
  };
}
