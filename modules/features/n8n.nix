{ self, ... }:
let
  inherit (self) catalog;
  port = 5678;
  webhookHost = catalog.services.n8n.tunnel.domain;
  communityNodes = [
    "n8n-nodes-imap"
  ];
in
{
  flake.modules.nixos.n8n = { config, lib, pkgs, ... }: {
    services.n8n = {
      enable = true;
      openFirewall = true;
      settings.port = port;
      webhookUrl = "https://${webhookHost}/";
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
    my.services.rsync.jobs.n8n = {
      destinations = [
        "nas-normal"
        "nas-minimal"
      ];
      paths = [ "${config.systemd.services.n8n.environment.N8N_USER_FOLDER}/" ];
      preHooks = [ "systemctl stop n8n.service" ];
      postHooks = [ "systemctl start n8n.service" ];
    };

    # Palvelun valvonta
    my.services.monitoring.checks = [
      {
        type = "http check";
        description = "N8N - web interface";
        secure = true;
        domain = catalog.services.n8n.public.domain;
        response.code = 200;
      }
    ];
  };

  # Tunneli webhookia varten
  flake.modules.nixos.n8n-tunnel = { config, ... }: {
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
