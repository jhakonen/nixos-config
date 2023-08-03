{ lib, pkgs, config, catalog, ... }:
let
  cfg = config.roles.paperless;

  # Näiden tulee vastata vastaavaa käyttäjää NAS:lla sillä tällä käyttäjällä
  # on luku/kirjoitus oikeus skannerin syötekansioon
  username = "skanneri";
  userId = 1029;
  userGroup = "users";  # Oletan että tämä on aina gid 100

  # Varmuuskopiokansio joka sisältää tietokannan ja dokumenttien exportin
  exportDir = "/var/backup/paperless-export";
in {
  options.roles.paperless = {
    enable = lib.mkEnableOption "Paperless rooli";
  };

  config = lib.mkIf cfg.enable {
    # Luo käyttäjä jota käytetään palvelun ajamiseen
    users.users.${username} = {
      group = userGroup;
      uid = userId;
      home = config.services.paperless.dataDir;
      isSystemUser = true;
    };

    services.paperless = {
      enable = true;
      extraConfig = {
        # Inotify ei toimi FTP jaon kanssa, pollaa sen sijaan
        # TODO: Toimiiko NFS:n yli?
        PAPERLESS_CONSUMER_POLLING = 60;  # sekunnin välein
        PAPERLESS_FILENAME_FORMAT = "{document_type}/{created_year}-{created_month}-{created_day} {title}";
        PAPERLESS_OCR_LANGUAGE = "fin";
        PAPERLESS_OCR_LANGUAGES = "fin";
        # TODO: Ota käyttöön
        #PAPERLESS_URL = "https://paperless.jhakonen.com";
      };
      port = catalog.services.paperless.port;
      address = "0.0.0.0";  # Salli pääsy palveluun koneen ulkopuolelta (oletuksena 'localhost')
      user = username;
    };

    # Avaa palomuuriin palvelulle reikä
    networking.firewall.allowedTCPPorts = [ config.services.paperless.port ];

    # Varmuuskopiointi
    services.backup = {
      preHooks = [
        # Exporttaa varmuuskopio
        "mkdir -p -m 777 ${exportDir}"
        "${pkgs.util-linux}/bin/runuser -u ${username} -- ${config.services.paperless.dataDir}/paperless-manage document_exporter --delete --use-filename-format --use-folder-prefix ${exportDir}"

        # Vedä alas paperlessin palvelut jotta tietokannan tiedostot voidaan
        # varmuuskopioida turvallisesti
        "systemctl stop paperless-consumer.service paperless-scheduler.service paperless-task-queue.service paperless-web.service"
      ];
      paths = [
        config.services.paperless.dataDir  # Paperlessin tietokanta ja dokumentit
        exportDir  # Exportti
      ];
      postHooks = [
        # Nosta palvelut takaisin ylös varmuuskopioinnin jälkeen
        "systemctl start paperless-consumer.service paperless-scheduler.service paperless-task-queue.service paperless-web.service"
      ];
      # document_exporter tarvitsee kirjoitusoikeudet data-hakemistoon
      readWritePaths = [ config.services.paperless.dataDir ];
    };

    # Liitä dokumenttien syötekansio NFS:n yli NAS:lta. Tähän kansioon skanneri
    # syöttää skannatut paperit
    fileSystems.${config.services.paperless.consumptionDir} = {
      device = "${catalog.nodes.nas.ip.private}:/volume1/scans";
      fsType = "nfs";
      options = [
        "noauto"
        "x-systemd.automount"
        "x-systemd.after=network-online.target"
        "x-systemd.mount-timeout=90"
        "x-systemd.idle-timeout=1min"
      ];
    };
  };
}
