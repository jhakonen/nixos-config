{ self, ... }:
let
  inherit (self) catalog;
  hubPort = catalog.services.seafile.port;
  fileServerPort = hubPort + 1;
in
{
  # Kanto-koneen konfiguraatio
  flake.modules.nixos.seafile = { config, ... }: {
    services.seafile = {
      enable = true;

      adminEmail = catalog.seafileAdminEmail;
      initialAdminPassword = "carenot";

      ccnetSettings.General.SERVICE_URL = "https://${catalog.services.seafile.public.domain}";

      seafileSettings = {
        fileserver = {
          host = "ipv4:0.0.0.0";
          port = fileServerPort;
        };
      };

      seahubAddress = "0.0.0.0:${toString hubPort}";
    };

    # Puhkaise reikä palomuuriin jotta tunneli-kone saa yhteyden palveluihin
    networking.firewall.allowedTCPPorts = [ hubPort fileServerPort ];

    # Varmuuskopiointi
    my.services.rsync.jobs.seafile = {
      destinations = [
        "nas-normal"
      ];
      preHooks = [
        "${config.services.mysql.package}/bin/mysqldump --user=root --opt ccnet_db > /tmp/ccnet_db.sql"
        "${config.services.mysql.package}/bin/mysqldump --user=root --opt seafile_db > /tmp/seafile_db.sql"
        "${config.services.mysql.package}/bin/mysqldump --user=root --opt seahub_db > /tmp/seahub_db.sql"
      ];
      paths = [
        "/tmp/ccnet_db.sql"
        "/tmp/seafile_db.sql"
        "/tmp/seahub_db.sql"
        "${config.services.seafile.dataDir}/"
      ];
      postHooks = [
        "rm --force /tmp/ccnet_db.sql /tmp/seafile_db.sql /tmp/seahub_db.sql"
      ];
      readWritePaths = [ "/tmp" ];
    };

    # Palvelun valvonta
    my.services.monitoring.checks = [
      {
        type = "http check";
        description = "Seafile - web";
        secure = true;
        domain = catalog.services.seafile.public.domain;
        path = "/accounts/login/";
        response.code = 200;
      }
    ];
  };

  # Tunneli-koneen konfiguraatio
  flake.modules.nixos.seafile-tunnel = { config, ... }: {
    services.nginx = {
      enable = true;
      virtualHosts.${catalog.services.seafile.public.domain} = {
        locations = {
          "/" = {
            proxyPass = "http://kanto.tailscale.jhakonen.com:${toString hubPort}"; # "http://unix:/run/seahub/gunicorn.sock";
            extraConfig = ''
              proxy_set_header   Host $host;
              proxy_set_header   X-Real-IP $remote_addr;
              proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header   X-Forwarded-Host $server_name;
              proxy_read_timeout  1200s;
              client_max_body_size 0;
            '';
          };
          "/seafhttp" = {
            proxyPass = "http://kanto.tailscale.jhakonen.com:${toString fileServerPort}"; # "http://unix:/run/seafile/server.sock";
            extraConfig = ''
              rewrite ^/seafhttp(.*)$ $1 break;
              client_max_body_size 0;
              proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_connect_timeout  36000s;
              proxy_read_timeout  36000s;
              proxy_send_timeout  36000s;
              send_timeout  36000s;
            '';
          };
        };
        # Käytä Let's Encrypt sertifikaattia
        addSSL = true;
        useACMEHost = "jhakonen.com";
      };
    };
  };
}
