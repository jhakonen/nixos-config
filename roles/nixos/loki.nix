{ config, ... }:
let
  catalog = config.dep-inject.catalog;
in
{
  # Grafanan Loki tietokanta joka vastaanottaa ja tallentaa lokirivejä
  services.loki = {
    enable = true;
    # Konfiguraatio osoitteesta: https://gist.github.com/rickhull/895b0cb38fdd537c1078a858cf15d63e
    configuration = {
      server.http_listen_port = catalog.services.loki.port;
      # Poista käytöstä jokin X-Scope-OrgID http otsikkoon perustuva
      # authentikaatio, miksi tämä on oletuksena true, wtf?
      auth_enabled = false;

      # Asetukset Lokin komponentille joka vastaanottaa ja indeksoi lokirivejä
      ingester = {
        lifecycler = {
          ring = {
            # Käytä muistia datan tallentamiseen, oletus: consul (jokin erillinen palvelu?)
            kvstore.store = "inmemory";
            # Rinnakkaisten ingestereiden lukumäärä, oletus: 3
            replication_factor = 1;
          };
        };
      };

      schema_config.configs = [{
        from = "2022-06-06";  # Vain jokin päivämäärä menneisyydessä, ei väliä mikä
        store = "boltdb-shipper";  # Indeksien tallennuspaikka
        object_store = "filesystem";  # Chunkien tallennuspaikka
        schema = "v11";  # Skeeman versio, v11 on suositeltu arvo
        index = {
          # Indeksien konfigurointia, en tiedä mitä nämä tekee
          prefix = "index_";
          period = "24h";
        };
      }];

      storage_config = {
        boltdb_shipper = {
          # Hakemisto johon ingester kirjoittaa indeksitiedostot
          active_index_directory = "${config.services.loki.dataDir}/boltdb-shipper-active";
          # Jokin cache hakemisto queryjä varten?
          cache_location = "${config.services.loki.dataDir}/boltdb-shipper-cache";
          # Paikka mihin indeksitiedostot tallennetaan
          shared_store = "filesystem";
        };

        # Chunkien tallennussijainti levyllä
        filesystem.directory = "${config.services.loki.dataDir}/chunks";
      };

      compactor = {
        # Hakemisto johon indeksi ladataan ennen datan pakkausta
        working_directory = config.services.loki.dataDir;
        # Paikka johon indeksit tallennetaan
        shared_store = "filesystem";
        # Käytä muistia datan tallentamiseen, oletus: consul (jokin erillinen palvelu?)
        compactor_ring.kvstore.store = "inmemory";
      };
    };
  };

  # Lisää Loki Grafanaan data sourceksi
  services.grafana.provision.datasources.settings.datasources = [{
    name = "Loki";
    type = "loki";
    url = "http://localhost:${toString catalog.services.loki.port}";
  }];

  # Lisää rooli lokiriveihin jotka Promtail lukee
  systemd.services.loki.serviceConfig.LogExtraFields = "ROLE=loki";

  networking.firewall.allowedTCPPorts = [ catalog.services.loki.port ];
}
