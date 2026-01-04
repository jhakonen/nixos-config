{ self, ... }: let
  inherit (self) catalog;
  agent-port = 45876;
in {
  flake.modules.nixos.nassuvm = { config, lib, pkgs, ... }: {
    imports = [ self.modules.nixos.beszel-agent ];

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
    #   Käynnistä: systemctl start restic-backups-beszel-hub.service
    #   Snapshotit: sudo restic-beszel-hub snapshots
    my.services.restic.backups.beszel-hub = {
      repository = "rclone:nas:/backups/restic/beszel-hub";
      paths = [
        "/var/lib/beszel-hub"
        "/var/lib/private/beszel-hub"
      ];
      backupPrepareCommand = "systemctl stop beszel-hub.service";
      backupCleanupCommand = "systemctl start beszel-hub.service";
      checkOpts = [ "--read-data" ];
      pruneOpts = [ "--keep-daily 7" "--keep-weekly 4" "--keep-monthly 12" ];
    };
  };

  flake.modules.nixos.beszel-agent = { config, lib, pkgs, ... }: {
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

  flake.modules.nixos.dellxps13 = { config, lib, pkgs, ... }: {
    imports = [ self.modules.nixos.beszel-agent ];
    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ agent-port ];
  };

  flake.modules.nixos.kanto = { config, lib, pkgs, ... }: {
    imports = [ self.modules.nixos.beszel-agent ];
    networking.firewall.allowedTCPPorts = [ agent-port ];
    # Lisää tuki podman konteille
    virtualisation.podman.dockerSocket.enable = true;
  };

  flake.modules.nixos.mervi = { config, lib, pkgs, ... }: {
    imports = [ self.modules.nixos.beszel-agent ];
    networking.firewall.allowedTCPPorts = [ agent-port ];
  };

  flake.modules.nixos.tunneli = { config, lib, pkgs, ... }: {
    imports = [ self.modules.nixos.beszel-agent ];
    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ agent-port ];
  };

  flake.modules.nixos.gatus = {
    # Palvelun valvonta
    services.gatus.settings.endpoints = [{
      name = "Beszel";
      url = "https://${catalog.services.beszel.public.domain}";
      conditions = [ "[STATUS] == 200" ];
    }];
  };
}
