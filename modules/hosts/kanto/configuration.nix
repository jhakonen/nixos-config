{ inputs, self, ... }: let
  inherit (self) catalog;
in {
  flake.modules.nixos.kanto = { config, pkgs, ... }: {
    # Ota flaket käyttöön
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    imports = [
      inputs.agenix.nixosModules.default
      inputs.home-manager.nixosModules.home-manager

      self.modules.nixos.service-monitoring
      self.modules.nixos.service-restic
      self.modules.nixos.service-syncthing

      self.modules.nixos.calibre
      self.modules.nixos.common
      self.modules.nixos.dashy
      self.modules.nixos.freshrss
      self.modules.nixos.gatus
      self.modules.nixos.gitea
      self.modules.nixos.grafana
      self.modules.nixos.home-assistant
      self.modules.nixos.immich
      self.modules.nixos.influxdb
      self.modules.nixos.karakeep
      self.modules.nixos.koti
      self.modules.nixos.mqtt-server
      self.modules.nixos.n8n
      self.modules.nixos.nginx
      self.modules.nixos.nix-cleanup
      self.modules.nixos.opencloud
      self.modules.nixos.paperless
      self.modules.nixos.radicale
      self.modules.nixos.syncthing-to-git
      self.modules.nixos.tailscale
      self.modules.nixos.telegraf
      self.modules.nixos.tvheadend
      self.modules.nixos.zigbee2mqtt
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
      mosquitto-password.file = ../../../agenix/mqtt-password.age;
      mosquitto-esphome-password.file = ../../../agenix/mqtt-espuser-password.age;
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

    # Tiedostojen synkkaus
    my.services.syncthing = {
      enable = true;
      gui-port = catalog.services.syncthing-kanto.port;
      user = "root";
      data-dir = "/root";
      settings = {
        devices = catalog.pickSyncthingDevices ["nas"];
        folders = {
          "Muistiinpanot" = {
            path = catalog.paths.syncthing.muistiinpanot;
            devices = [ "nas" ];
          };
          "Päiväkirja" = {
            path = catalog.paths.syncthing.paivakirja;
            devices = [ "nas" ];
          };
        };
      };
    };


    # Älä muuta ellei ole pakko, ei edes uudempaan versioon päivittäessä
    system.stateVersion = "24.05";
  };

  flake.modules.homeManager.kanto = {
    # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
    home.stateVersion = "24.05";
  };

  flake.modules.nixos.gatus = {
    # Palvelun valvonta
    services.gatus.settings.endpoints = [{
      name = "Syncthing (kanto)";
      url = "http://${catalog.services.syncthing-kanto.host.hostName}:${toString catalog.services.syncthing-kanto.port}";
      conditions = [ "[STATUS] == 200" ];
    }];
  };
}
