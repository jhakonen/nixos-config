{ config, den, ... }: let
  inherit (config) catalog;
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

    ################################################
    # Korjaa Systemd palvelujen monitorointi
    # https://github.com/NixOS/nixpkgs/pull/461327
    users.users.beszel-agent = {
      isSystemUser = true;
      group = "beszel-agent";
    };
    users.groups.beszel-agent = {};
    systemd.services.beszel-agent.serviceConfig = {
      DynamicUser = lib.mkForce false;
      Group = "beszel-agent";
      SupplementaryGroups = [ "messagebus" ];
    };
    ################################################
  };

  den.aspects.nassuvm = {
    includes = [ den.aspects.beszel-agent ];
    nixos = { pkgs, ... }: {
      services.beszel.hub = {
        enable = true;
        package = pkgs.unstable.beszel;
        port = catalog.services.beszel.port;
        environment = {
          # Aseta Hubin URL-osoite notifikaatioita varten
          APP_URL = "https://${catalog.services.beszel.public.domain}";
        };
      };

      services.nginx.virtualHosts.${catalog.services.beszel.public.domain} = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString catalog.services.beszel.port}";
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

      # Palvelun valvonta
      services.gatus.settings.endpoints = [{
        name = "Beszel";
        url = "https://${catalog.services.beszel.public.domain}";
        conditions = [ "[STATUS] == 200" ];
      }];
    };
  };

  den.aspects.dellxps13 = {
    includes = [ den.aspects.beszel-agent ];
    nixos = {
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ agent-port ];
    };
  };

  den.aspects.kanto = {
    includes = [ den.aspects.beszel-agent ];
    nixos = {
      networking.firewall.allowedTCPPorts = [ agent-port ];
      # Lisää tuki podman konteille
      virtualisation.podman.dockerSocket.enable = true;
    };
  };

  den.aspects.mervi = {
    includes = [ den.aspects.beszel-agent ];
    nixos = {
      networking.firewall.allowedTCPPorts = [ agent-port ];
    };
  };

  den.aspects.tunneli = {
    includes = [ den.aspects.beszel-agent ];
    nixos = {
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ agent-port ];
    };
  };
}
