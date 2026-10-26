# Uuden koneen lisääminen:
#  - Tee palomuuriin reikä portille `agent-port` monitoroitavalle koneelle
#  - Avaa https://beszel.nassuvm.lan.jhakonen.com/ ja klikkaa "Add system".
#    Anna koneelle nimi ja host/ip -osoite. Muista käyttää koneen palomuurin
#    rajapinnan osoitetta.
{ den, ... }: let
  agent-port = 45876;
in {
  den.aspects.beszel-agent.nixos = { lib, pkgs, ... }: {
    services.beszel.agent = {
      enable = true;
      package = pkgs.unstable.beszel;
      environment = {
        LISTEN = toString agent-port;
        # Bezsel-hub luo avaimen itse, avain kopioitu "Add System" dialogista
        KEY = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIASoKzcQ8/e5ggX73nlVsQvVykW87oWHmQznDfTBv65+";
      };
    };
  };

  den.aspects.nassuvm.nixos = { config, lib, pkgs, ... }: {
    services.beszel.hub = {
      enable = true;
      package = pkgs.unstable.beszel;
      port = config.catalog.services.beszel.port;
      environment = {
        # Aseta Hubin URL-osoite notifikaatioita varten
        APP_URL = "https://${config.catalog.services.beszel.public.domain}";
      };
    };

    # Korjaa ongelman https://github.com/NixOS/nixpkgs/pull/539583
    # Tämän voinee poistaa NixOS 26.11 versiossa.
    systemd.services.beszel-hub.serviceConfig.ExecStartPre = lib.mkForce [
      "${config.services.beszel.hub.package}/bin/beszel-hub migrate up"
      "${config.services.beszel.hub.package}/bin/beszel-hub migrate history-sync"
    ];

    services.nginx.virtualHosts.${config.catalog.services.beszel.public.domain} = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.catalog.services.beszel.port}";
        proxyWebsockets = true;
        recommendedProxySettings = true;
      };
      # Käytä Let's Encrypt sertifikaattia
      addSSL = true;
      useACMEHost = "nassuvm.lan.jhakonen.com";
    };

    # Varmuuskopiointi
    #   Käynnistä:
    #     systemctl start restic-backups-beszel-hub-oma.service
    #     systemctl start restic-backups-beszel-hub-veli.service
    #   Snapshotit:
    #     sudo restic-beszel-hub-oma snapshots
    #     sudo restic-beszel-hub-veli snapshots
    my.services.restic.backups = let
      bConfig = {
        paths = [
          "/var/lib/beszel-hub"
          "/var/lib/private/beszel-hub"
        ];
        backupPrepareCommand = "systemctl stop beszel-hub.service";
        backupCleanupCommand = "systemctl start beszel-hub.service";
      };
    in {
      beszel-hub-oma = bConfig // {
        repository = "rclone:nas-oma:/backups/restic/beszel-hub";
        timerConfig.OnCalendar = "01:00";
      };
      beszel-hub-veli = bConfig // {
        repository = "rclone:nas-veli:/home/restic/beszel-hub";
        timerConfig.OnCalendar = "Sat 02:00";
      };
    };
  };

  den.default = {
    includes = [ den.aspects.beszel-agent ];
  };

  den.aspects.dellxps13.nixos = {
    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ agent-port ];
  };

  den.aspects.raami.nixos = {
    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ agent-port ];
  };

  den.aspects.kanto.nixos = { config, ... }: {
    networking.firewall.allowedTCPPorts = [ agent-port ];
    # Lisää tuki podman konteille
    virtualisation.podman.dockerSocket.enable = true;

    # Palvelun valvonta
    services.gatus.settings.endpoints = [{
      name = "Beszel";
      url = "https://${config.catalog.services.beszel.public.domain}";
      conditions = [ "[STATUS] == 200" ];
    }];
  };

  den.aspects.mervi.nixos = {
    networking.firewall.allowedTCPPorts = [ agent-port ];
  };

  den.aspects.tunneli.nixos = {
    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ agent-port ];
  };
}
