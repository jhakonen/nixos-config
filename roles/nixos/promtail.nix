{ config, ... }:
let
  catalog = config.dep-inject.catalog;
in
{
  # Tämä palvelu kerää järjestelmästä lokirivejä jotka se lähettää Grafanan Loki
  # kantaan. Grafanassa voi sitten selata ja hakea palveluiden lokeja.
  services.promtail = {
    enable = true;
    configuration = {
      # Sulje Promtailin HTTP ja gRPC portit
      server.disable = true;
      # Polku tiedostoon joka sisältää tiedon mihin asti kutakin lokia on
      # luettu, tarpeen jos Promtail käynnistetään uudelleen
      positions.filename = "/tmp/positions.yaml";
      clients = [{
        # Loki-kannan osoite johon lokirivit lähetetään
        url = "http://${catalog.getServiceAddress(catalog.services.loki)}:${toString catalog.services.loki.port}/loki/api/v1/push";
      }];
      scrape_configs = [{
        # Konffan nimi, pakollinen, en tiedä miksi tarvitaan
        job_name = "journal";
        journal = {
          # json = true;  # Debuggaukseen: kätevä jos haluaa nähdä mitä systemd
                          # fieldejä on saatavilla
          labels = {
            # Lisää labeleja jokaiseen lokiriviin
            job = "systemd-journal";
            host = config.networking.hostName;
          };
        };
        relabel_configs = [{
          # Poimi systemd palvelun nimi ja välitä se Loki-kantaan unit-labelina
          source_labels = [ "__journal__systemd_unit" ];
          target_label = "unit";
        } {
          # Poimi journaldin ROLE-field (joka asetetaan LogExtraFields
          # muuttujalla) ja välitä se Loki-kantaan role-labelina
          source_labels = [ "__journal_role" ];
          target_label = "role";
        }];
      }];
    };
  };

  # Lisää rooli lokiriveihin jotka Promtail lukee
  systemd.services.promtail.serviceConfig.LogExtraFields = "ROLE=promtail";
}
