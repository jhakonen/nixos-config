{ catalog, config, lib, ... }:
let
  LOCAL_LIBRARY_PATH = "/mnt/calibre";
  REMOTE_LIBRARY_PATH = "/volume1/calibre";
  # Nämä ID arvot tulee olla samat kuin Synologyssä
  USER = "calibre";
  USER_ID = 1033;
  GROUP = "calibre";
  GROUP_ID = 65539;
in {
  services = {
    calibre-web = {
      enable = true;
      listen = {
        ip = "127.0.0.1";
        port = catalog.services.calibre-web.port;
      };
      user = USER;
      group = GROUP;
      options = {
        calibreLibrary = LOCAL_LIBRARY_PATH;
      };
    };

    nginx.virtualHosts.${catalog.services.calibre-web.public.domain} = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.calibre-web.listen.port}";
        recommendedProxySettings = true;
      };
      # Käytä Let's Encrypt sertifikaattia
      addSSL = true;
      useACMEHost = "jhakonen.com";
      extraConfig = ''
        # Salli upotus Dashyn iframeen
        proxy_hide_header Content-Security-Policy;
        add_header Content-Security-Policy "frame-ancestors 'self' https://${catalog.services.dashy.public.domain} ;" always;
      '';
    };
  };

  users = lib.mkIf config.services.calibre-web.enable {
    users.${USER} = {
      isSystemUser = true;
      group = GROUP;
      uid = USER_ID;
    };
    groups.${GROUP}.gid = GROUP_ID;
  };

  # Liitä Calibren kirjasto NFS:n yli NAS:lta
  fileSystems.${LOCAL_LIBRARY_PATH} = {
    device = "${catalog.nodes.nas.ip.private}:${REMOTE_LIBRARY_PATH}";
    fsType = "nfs";
    options = [
      "noauto"
      "x-systemd.automount"
      "x-systemd.after=network-online.target"
      "x-systemd.mount-timeout=90"
    ];
  };
}
