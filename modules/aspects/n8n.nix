{ self, config, ... }:
let
  inherit (config) catalog;
  port = 5678;
  webhookHost = catalog.services.n8n.tunnel.domain;
  communityNodes = [
    # n8n-nodes-imap@2.13.0 ei toimi, joten palautin version käyttöön joka
    # minulla oli elokuussa kun loin sähköpostiflown. Se toimii.
    "n8n-nodes-imap@2.10.0"
  ];
in
{
  den.aspects.kanto.nixos = { lib, pkgs, ... }: {
    services.n8n = {
      enable = true;
      openFirewall = true;
      environment = {
        N8N_PORT = port;
        WEBHOOK_URL = "https://${webhookHost}/";
      };
    };

    # Asenna community nodes lisäosia, koodi otettu reposta:
    # https://github.com/GGG-KILLER/nixos-configs/blob/63ac908bc4b43d026f5274000b3d6054e239d4c8/hosts/jibril/system/services/n8n.nix#L13
    systemd.services.n8n.serviceConfig.ExecStartPre =
      pkgs.writeShellScript "n8n-pre-start.sh" ''
        set -euo pipefail

        mkdir -p "$N8N_USER_FOLDER"/.n8n/nodes
        pushd "$N8N_USER_FOLDER"/.n8n/nodes
          ${pkgs.nodejs}/bin/npm install -y ${lib.escapeShellArgs communityNodes}
        popd
      '';

    # systemd.services.n8n.environment = {
    #   N8N_LOG_LEVEL = "debug";
    # };

    services.nginx = {
      enable = true;
      virtualHosts.${catalog.services.n8n.public.domain} = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString port}";
          proxyWebsockets = true;
          recommendedProxySettings = true;
        };
        # Käytä Let's Encrypt sertifikaattia
        addSSL = true;
        useACMEHost = "jhakonen.com";
      };
    };

    # Varmuuskopiointi
    #   Käynnistä:
    #     systemctl start restic-backups-n8n-oma.service
    #     systemctl start restic-backups-n8n-veli.service
    #   Snapshotit:
    #     sudo restic-n8n-oma snapshots
    #     sudo restic-n8n-veli snapshots
    my.services.restic.backups = let
      bConfig = {
        paths = [
          "/var/lib/n8n"
          "/var/lib/private/n8n"
        ];
        backupPrepareCommand = "systemctl stop n8n.service";
        backupCleanupCommand = "systemctl start n8n.service";
      };
    in {
      n8n-oma = bConfig // {
        repository = "rclone:nas-oma:/backups/restic/n8n";
        timerConfig.OnCalendar = "01:00";
      };
      n8n-veli = bConfig // {
        repository = "rclone:nas-veli:/home/restic/n8n";
        timerConfig.OnCalendar = "Sat 02:00";
      };
    };

    # Palvelun valvonta
    services.gatus.settings.endpoints = [{
      name = "N8N";
      url = "https://${catalog.services.n8n.public.domain}";
      conditions = [ "[STATUS] == 200" ];
    }];
  };

  # Tunneli webhookia varten
  den.aspects.tunneli.nixos = {
    services.nginx = {
      enable = true;
      virtualHosts.${webhookHost} = {
        locations."/" = {
          proxyPass = "http://kanto.tailscale.jhakonen.com:${toString port}";
          proxyWebsockets = true;
          recommendedProxySettings = true;
        };
        # Käytä Let's Encrypt sertifikaattia
        addSSL = true;
        useACMEHost = "jhakonen.com";
      };
    };
  };
}
