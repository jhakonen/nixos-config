{ self, ... }:
let
  inherit (self) catalog;
  hubPort = catalog.services.seafile.port;
  fileServerPort = hubPort + 1;
  syslogPort = 10514;
in
{
  # Kanto-koneen konfiguraatio
  flake.modules.nixos.seafile = { config, lib, pkgs, ... }: {
    services.seafile = {
      enable = true;
      gc.enable = true;

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
      seahubExtraConf = ''
        # Fail2ban tarvitsee tämän asetuksen
        TIME_ZONE = 'Europe/Helsinki'
      '';
    };

    # Puhkaise reikä palomuuriin jotta tunneli-kone saa yhteyden palveluihin
    networking.firewall.allowedTCPPorts = [ hubPort fileServerPort ];

    # # Välitä Seahubin loki tunneli koneelle (fail2ban palvelua varten)
    services.rsyslogd = {
      enable = true;
      extraConfig = ''
        module(load="imfile")

        # Lue Seahubin lokit jotka sisältävät viestit jos sisääkirjautuminen
        # epäonnistuu. Tunneli-koneen fail2ban tarvitsee ne.
        input(
          type="imfile"
          File="/var/log/seafile/seahub.log"
          Tag="seahub"
          Facility="auth"
        )

        # Välitä lokit tunneli-koneelle
        :syslogtag, isequal, "seahub" action(
          type="omfwd"
          target="${catalog.nodes.tunneli.ip.tailscale}"
          port="${toString syslogPort}"
          protocol="tcp"
        )
      '';
    };

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
          };
          "/seafhttp" = {
            proxyPass = "http://kanto.tailscale.jhakonen.com:${toString fileServerPort}"; # "http://unix:/run/seafile/server.sock";
            extraConfig = ''
              rewrite ^/seafhttp(.*)$ $1 break;
            '';
          };
        };
        # Käytä Let's Encrypt sertifikaattia
        addSSL = true;
        useACMEHost = "jhakonen.com";
      };
    };

    # Estä yhteydenotot jos sisäänkirjautuminen epäonnistuu tarpeeksi monta kertaa.
    services.fail2ban = {
      enable = true;
      # Konfiguraatio tehty näiden ohjeiden pohjalta:
      #   https://manual.seafile.com/11.0/security/fail2ban/
      jails.seafile = {
        filter.Definition = {
          _daemon = "seaf-server";
          failregex = "Login attempt limit reached.*, ip: <HOST>";
          ignoreregex = "";
        };
        settings = {
          maxretry = 3;
          port = "http,https";
        };
      };
    };

    # Seahubin lokien vastaanottava osa. Vastaanotetut lokit kirjoitetaan
    # journaliin.
    services.rsyslogd = {
      enable = true;
      extraConfig = ''
        module(load="imtcp")
        module(load="omjournal")

        # Vastaanota syslog viestit kanto-koneelta
        input(type="imtcp" port="${toString syslogPort}")

        # Välitä seahub viestit systemd journaliin, fail2ban lukee ne sieltä
        :syslogtag, isequal, "seahub" action(type="omjournal")
      '';
    };

    # Salli lokien vastaanottaminen vain Tailscale verkosta, ei julkisesta
    # internetistä.
    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ syslogPort ];
  };
}
