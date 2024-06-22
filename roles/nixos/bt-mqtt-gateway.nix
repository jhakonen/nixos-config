{ config, pkgs, ... }:
let
  catalog = config.dep-inject.catalog;
  my-packages = config.dep-inject.my-packages;

  # checkBluetoothExists = pkgs.writeShellScript "bluetooth-exists" ''
  #   ${pkgs.bluez}/bin/hcitool dev | ${pkgs.gnugrep}/bin/grep -o 'hci[0-9]' >/dev/null
  # '';

  # checkRuuviTagsUpdated = pkgs.writeShellScript "check-ruuvitags-updated" ''
  #   if [ $(${pkgs.systemd}/bin/systemctl show -p ActiveState --value bt-mqtt-gateway.service) != "inactive" ]; then
  #     ${pkgs.systemd}/bin/journalctl -u bt-mqtt-gateway.service --since "15 min ago" | grep -s "Updating ruuvitag"
  #   fi
  # '';

  resetBtDongle = pkgs.writeShellScript "reset-bt-dongle-and-service" ''
    echo "Kytke virrat pois/päälle Bluetooth donglesta"
    uhubctl --action=cycle --search='Realtek ASUS USB-BT500'
    echo "Odota hetki jotta Bluetooth laite käynnistyy"
    sleep 5
  '';

  # resetBtDongleAndService = pkgs.writeShellScript "reset-bt-dongle-and-service" ''
  #   systemctl stop bt-mqtt-gateway.service
  #   ${resetBtDongle}
  #   systemctl start bt-mqtt-gateway.service
  # '';


  gatewayConfig = {
    mqtt = {
      host = catalog.services.mosquitto.public.domain;
      port = catalog.services.mosquitto.port;
      username = "koti";
      password = "$MQTT_PASSWORD";
      ca_cert = "/etc/ssl/certs/ca-bundle.crt";
      ca_verify = false;
      topic_prefix = "bt-mqtt-gateway";
      client_id = "bt-mqtt-gateway";
      availability_topic = "availability";
    };
    manager = {
      command_timeout = 30;
      sensor_config = {
        topic = "homeassistant";
        retain = true;
      };
      topic_subscription.update_all = {
        topic = "homeassistant/status";
        payload = "online";
      };
      workers.ruuvitag = {
        args = {
          devices = {
            sauna = "FB:F4:05:4A:70:70";
            makuuhuone = "E2:7D:43:DE:99:0C";
            ulkona = "D4:43:1D:F2:66:45";
          };
          topic_prefix = "ruuvitag";
          no_data_timeout = 600;
        };
      };
    };
  };
  configFile = (pkgs.formats.yaml {}).generate "bt-mqtt-gateway.yaml" gatewayConfig;
  dataDir = "/var/lib/bt-mqtt-gateway";
in
{
  # TODO myöhemmin: Luo käyttäjä jolla palvelua ajetaan, bluez-pohjainen
  # ruuvitagin toteutus vaatii käyttäjän jolla sudo oikeus suorittaa hci*
  # -työkaluja ilman salasanaa. Vaihda toteutus Bleak-kirjastoon, näin sudo
  # -vaatimuskin saattaa poistua

  age.secrets.bt-mqtt-gateway-environment.file = ../../secrets/bt-mqtt-gateway-environment.age;

  systemd.services.bt-mqtt-gateway = {
    description = "bt-mqtt-gateway palvelu";
    wantedBy = [ "multi-user.target" ];
    path = [
      pkgs.bluez  # Lisää hci* työkalut polulle
      pkgs.coreutils  # head
      pkgs.envsubst
      pkgs.gnugrep
      pkgs.uhubctl
    ];
    preStart = ''
      set +e

      function get-bt-device() {
        hcitool dev | grep -o 'hci[0-9]' | head -n1
      }

      umask 077
      mkdir -p ${dataDir}
      envsubst -i "${configFile}" -o "${dataDir}/bt-mqtt-gateway.yaml"

      #DEV_NAME=$(get-bt-device)
      #if [ "$DEV_NAME" == "" ]; then
        ${resetBtDongle}
      #fi
      '';
    serviceConfig = {
      Environment = "CONFIG_FILE=${dataDir}/bt-mqtt-gateway.yaml";
      EnvironmentFile = [ config.age.secrets.bt-mqtt-gateway-environment.path ];
      ExecStart = "${my-packages.bt-mqtt-gateway}/bin/bt-mqtt-gateway";
      Restart = "always";
      RestartSec = "30";
      LogExtraFields = "ROLE=bt-mqtt-gateway";
    };
    unitConfig = {
      # Käynnistä palvelu kun "Bluetooth interface has gone down" virhe tapahtuu, mutta rajoita
      # kuinka monta kertaa uudelleen käynnistys saa tapahtua jotta monitorointi havaitsee ongelman
      StartLimitIntervalSec = "200";
      StartLimitBurst = "5";
    };
  };

  environment.systemPackages = [ pkgs.uhubctl ];

  # Palvelun valvonta
  my.services.monitoring.checks = [
    {
      type = "systemd service";
      description = "bt-mqtt-gateway";
      name = config.systemd.services.bt-mqtt-gateway.name;
      expected = "running";
    }
    # ({ notify, secsToCycles, ... }: ''
    #   check program "Reboot if Bluetooth device disappears" with path "${checkBluetoothExists}"
    #     if status != 0 then alert
    #     if status != 0 for ${secsToCycles (15 * 60)} cycles then
    #       exec "${notify} Bluetooth ${config.networking.hostName} koneella on ollut alhaalla 15 minuuttia, uudelleen käynnistys kohta"
    #     if status != 0 for ${secsToCycles (20 * 60)} cycles then
    #       exec "${pkgs.systemd}/bin/systemctl reboot"
    # '')
    # ({ notify, secsToCycles, ... }: ''
    #   check program "Power cycle Bluetooth if no data" with path "${checkRuuviTagsUpdated}"
    #     if status != 0 then alert
    #     if status != 0 for ${secsToCycles (5 * 60)} cycles then
    #       exec "${notify} Ei ruuvitag dataa ${config.networking.hostName} koneella on 20 minuuttiin, nollaa bt dongle"
    #     if status != 0 for ${secsToCycles (5 * 60)} cycles then
    #       exec "${resetBtDongleAndService}"
    # '')
  ];
}
