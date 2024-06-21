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
    preHooks = [ "systemctl stop phpfpm-freshrss.service" ];
    postHooks = [ "systemctl start phpfpm-freshrss.service" ];
  };
}