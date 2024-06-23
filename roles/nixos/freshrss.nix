{ config, pkgs, ... }:
let
  catalog = config.dep-inject.catalog;
in
{
  age.secrets.freshrss-admin-password = {
    file = ../../secrets/freshrss-admin-password.age;
    owner = config.services.freshrss.user;
  };

  services.freshrss = {
    enable = true;
    baseUrl = "https://${catalog.services.freshrss.public.domain}";
    virtualHost = catalog.services.freshrss.public.domain;
    # Jos salasanaa vaihtaa niin tulee ajaa freshrss-config.service uudelleen
    passwordFile = config.age.secrets.freshrss-admin-password.path;
  };

  # https://github.com/NixOS/nixpkgs/issues/316624
  systemd.services.freshrss-config = {
    restartIfChanged = true;
    serviceConfig.RemainAfterExit = true;
  };

  services.nginx = {
    enable = true;
    virtualHosts.${catalog.services.freshrss.public.domain} = {
      # Käytä Let's Encrypt sertifikaattia
      addSSL = true;
      useACMEHost = "jhakonen.com";
    };
  };

  # Varmuuskopiointi
  my.services.rsync.jobs.freshrss = {
    destinations = [
      "nas-normal"
      "nas-minimal"
    ];
    paths = [ "${config.services.freshrss.dataDir}/" ];
    preHooks = [
      "systemctl stop freshrss-updater.timer"
      "systemctl stop freshrss-updater.service"
    ];
    postHooks = [
      "systemctl start freshrss-updater.timer"
    ];
  };

  # Palvelun valvonta
  my.services.monitoring.checks = [
    {
      type = "systemd service";
      description = "FreshRSS - service";
      name = config.systemd.services.phpfpm-freshrss.name;
      expected = "running";
    }
    {
      type = "systemd service";
      description = "FreshRSS - updater";
      name = config.systemd.services.freshrss-updater.name;
      expected = "succeeded";
    }
    {
      type = "http check";
      description = "FreshRSS - web interface";
      secure = true;
      domain = catalog.services.freshrss.public.domain;
      path = "/i/";
      response.code = 200;
    }
  ];
}