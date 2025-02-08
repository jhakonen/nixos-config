{ config, flake, pkgs, ... }:
let
  inherit (flake.lib) catalog;

  # Näiden tulee vastata vastaavaa käyttäjää NAS:lla sillä tällä käyttäjällä
  # on luku/kirjoitus oikeus skannerin syötekansioon
  username = "skanneri";
  userId = 1029;
  userGroup = "users";  # Oletan että tämä on aina gid 100

  # Varmuuskopiokansio joka sisältää tietokannan ja dokumenttien exportin
  exportDir = "${config.services.paperless.dataDir}/exports";
in {
  # Luo käyttäjä jota käytetään palvelun ajamiseen
  users.users.${username} = {
    group = userGroup;
    uid = userId;
    home = config.services.paperless.dataDir;
    isSystemUser = true;
  };

  services.paperless = {
    enable = true;
    settings = {
      # Inotify ei toimi FTP jaon kanssa, pollaa sen sijaan
      # TODO: Toimiiko NFS:n yli?
      PAPERLESS_CONSUMER_POLLING = 60;  # sekunnin välein
      PAPERLESS_FILENAME_FORMAT = "{document_type}/{created_year}-{created_month}-{created_day} {title}";
      PAPERLESS_OCR_LANGUAGE = "fin";
      PAPERLESS_OCR_LANGUAGES = "fin";
      # Tämä tarvitaan jotta Paperless ei estä pääsyä CSRF tarkistuksen takia
      PAPERLESS_URL = "${catalog.getServiceScheme catalog.services.paperless}://${catalog.getServiceAddress catalog.services.paperless}";
      # Sähköpostin skannaus-workeri meni jumiin ja söi 70% cputa, otetaan pois käytöstä
      PAPERLESS_EMAIL_TASK_CRON = "disable";
    };
    port = catalog.services.paperless.port;
    address = "0.0.0.0";  # Salli pääsy palveluun koneen ulkopuolelta (oletuksena 'localhost')
    user = username;
  };

  services.nginx = {
    enable = true;
    virtualHosts.${catalog.services.paperless.public.domain} = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString catalog.services.paperless.port}";
        proxyWebsockets = true;
        recommendedProxySettings = true;
      };
      # Käytä Let's Encrypt sertifikaattia
      addSSL = true;
      useACMEHost = "jhakonen.com";
    };
  };

  # Avaa palomuuriin palvelulle reikä
  networking.firewall.allowedTCPPorts = [ catalog.services.paperless.public.port ];

  # Varmuuskopiointi
  my.services.rsync.jobs.paperless = {
    destinations = [
      "nas-normal"
      "nas-minimal"
    ];
    preHooks = [
      # Exporttaa varmuuskopio
      "ls ${exportDir}" # Herätä NFS mountti niin että se näyttää kirjoitettavalta, muuten document_exporter herjaa siittä
      "chown ${username}:${userGroup} ${exportDir}"
      "${pkgs.util-linux}/bin/runuser -u ${username} -- ${config.services.paperless.dataDir}/paperless-manage document_exporter --delete --use-filename-format --use-folder-prefix ${exportDir}"

      # Vedä alas paperlessin palvelut jotta tietokannan tiedostot voidaan
      # varmuuskopioida turvallisesti
      "systemctl stop paperless-consumer.service paperless-scheduler.service paperless-task-queue.service paperless-web.service"
    ];
    paths = [
      "${config.services.paperless.dataDir}/"  # Paperlessin tietokanta ja dokumentit
    ];
    postHooks = [
      # Nosta palvelut takaisin ylös varmuuskopioinnin jälkeen
      "systemctl start paperless-consumer.service paperless-scheduler.service paperless-task-queue.service paperless-web.service"
    ];
    # document_exporter tarvitsee kirjoitusoikeudet data-hakemistoon
    readWritePaths = [ config.services.paperless.dataDir ];
    excludes = [ "${config.services.paperless.dataDir}/consume" ];
  };

  # Palvelun valvonta
  my.services.monitoring.checks = [
    {
      type = "systemd service";
      description = "Paperless - consumer";
      name = config.systemd.services.paperless-consumer.name;
    }
    {
      type = "systemd service";
      description = "Paperless - scheduler";
      name = config.systemd.services.paperless-scheduler.name;
    }
    {
      type = "systemd service";
      description = "Paperless - task-queue";
      name = config.systemd.services.paperless-task-queue.name;
    }
    {
      type = "systemd service";
      description = "Paperless - web service";
      name = config.systemd.services.paperless-web.name;
    }
    {
      type = "http check";
      description = "Paperless - web interface";
      secure = true;
      domain = catalog.services.paperless.public.domain;
      path = "/accounts/login/";
      response.code = 200;
    }
  ];

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
    ];
  };

  # Liitä Paperlessin exporttikansio NFS:n yli NAS:lta
  fileSystems.${exportDir} = {
    device = "${catalog.nodes.nas.ip.private}:/volume1/paperless";
    fsType = "nfs";
    options = [
      "noauto"
      "x-systemd.automount"
      "x-systemd.after=network-online.target"
      "x-systemd.mount-timeout=90"
    ];
  };
}
