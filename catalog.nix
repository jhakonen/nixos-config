# Perustuu ideaan blogista: https://jdheyburn.co.uk/blog/automating-service-configurations-with-nixos/
{ nixpkgs, ... }:
with nixpkgs;
let
  # Lisää node.hostName attribuutti jokaiseen nodeen
  addHostNames = nodes: builtins.mapAttrs (hostName: node: { inherit hostName; } // node) nodes;

  # Lisää service.name attribuutti jokaiseen palveluun
  addServiceNames = services: builtins.mapAttrs (name: service: { inherit name; } // service) services;

  # Muuttaa kunkin sanan ensimmäisen kirjaimen isoksi
  capitalize = input: builtins.concatStringsSep " " (map (word: capitalizeWord word) (lib.strings.splitString " " input));

  # Muuttaa merkkijonon esnsimmäisen kirjaimen isoksi
  capitalizeWord = word: (lib.strings.toUpper (builtins.substring 0 1 word)) + builtins.substring 1 1000 word;

  # Muuttaa merkkijonon erikoismerkit välilyönneiksi
  specialCharsToSpaces = input: lib.strings.stringAsChars (c: if (builtins.match "[-_]" c) == [] then " " else c) input;

  # Palauttaa palvelun nimen
  getServiceName = service: capitalize (specialCharsToSpaces service.name);

  # Palauttaa palvelun skeeman, eli http tai https, riippuen portista jota käytetään
  getServiceScheme = service: if ((service ? https) && service.https) || (getServicePort service) == 443 then "https" else "http";

  # Palauttaa palvelun portin
  getServicePort = service:
    if (service ? public.port) then
      service.public.port
    else
      service.port
    ;

  # Palauttaa palvelun osoitteen
  getServiceAddress = service:
    if (service ? public.domain) then
      service.public.domain
    else if (service ? host.useIp && service.host.useIp) then
      service.host.ip.private
    else
      service.host.hostName
    ;
in rec {
  inherit getServiceName;
  inherit getServiceScheme;
  inherit getServicePort;
  inherit getServiceAddress;

  pickSyncthingDevices = names:
    lib.filterAttrs (n: v: lib.elem n names) syncthing-devices;

  nodes = addHostNames {
    asus-router = {
      ip.private = "192.168.1.1";
      useIp = true;
    };
    modeemi = {
      ip.private = "192.168.100.1";
      useIp = true;
    };
    dellxps13 = {};
    kanto = {
      ip.private = "192.168.1.86";
    };
    mervi = {};
    nas = {
      ip.private = "192.168.1.101";
    };
    nas-nextcloud-vm = {
      ip.private = "192.168.1.49";
    };
    hl-l2445dw = { # tulostin
      ip.private = "192.168.1.76";
      useIp = true;
    };
    ads-1700w = { # skanneri
      ip.private = "192.168.1.218";
      useIp = true;
    };
    tinypilot = {};
    toukka = {
      ip.private = "192.168.1.68";
    };
  };

  services = addServiceNames {
    calibre-web = {
      host = nodes.kanto;
      port = 17000;
      dashy = {
        section = "viihde";
        description = "E-kirjojen selaus";
        icon = "hl-calibre";
      };
      public = {
        domain = "calibre-web.jhakonen.com";
        port = 443;
      };
    };
    dashy = {
      host = nodes.kanto;
      port = 13000;
      public = {
        domain = "dashy.jhakonen.com";
      };
    };
    freshrss = {
      host = nodes.kanto;
      dashy = {
        section = "palvelut";
        description = "RSS lukija";
        icon = "hl-freshrss";
      };
      public = {
        domain = "freshrss.jhakonen.com";
        port = 443;
      };
    };
    grafana = {
      host = nodes.kanto;
      port = 3000;
      dashy = {
        section = "valvonta";
        description = "Järjestelmän valvonta";
        icon = "hl-grafana";
      };
      public = {
        domain = "grafana.jhakonen.com";
        port = 443;
      };
    };
    home-assistant = {
      host = nodes.kanto;
      port = 8123;
      dashy = {
        section = "palvelut";
        description = "Kotiautomaation hallinta";
        icon = "hl-home-assistant";
      };
      public = {
        domain = "home-assistant.jhakonen.com";
        port = 443;
      };
    };
    huginn = {
      host = nodes.kanto;
      port = 14000;
      dashy = {
        section = "palvelut";
        description = "Tehtävien automatisointi";
        icon = "hl-huginn";
      };
      public = {
        domain = "huginn.jhakonen.com";
        port = 443;
      };
    };
    influx-db = {
      host = nodes.kanto;
      port = 8086;
    };
    kodi = {
      host = nodes.mervi;
      port = 8080;
      dashy = {
        section = "viihde";
        description = "Kodin hallintapaneeli";
        icon = "hl-kodi";
      };
    };
    monit-kanto = {
      host = nodes.kanto;
      dashy = {
        section = "valvonta";
        description = "Monit - kanto";
        icon = "hl-monit";
      };
      public = {
        domain = "monit.kanto.lan.jhakonen.com";
        port = 443;
      };
    };
    monit-mervi = {
      host = nodes.mervi;
      dashy = {
        section = "valvonta";
        description = "Monit - mervi";
        icon = "hl-monit";
      };
      public = {
        domain = "monit.mervi.lan.jhakonen.com";
        port = 443;
      };
    };
    monit-toukka = {
      host = nodes.toukka;
      dashy = {
        section = "valvonta";
        description = "Monit - toukka";
        icon = "hl-monit";
      };
      public = {
        domain = "monit.toukka.lan.jhakonen.com";
        port = 443;
      };
    };
    modeemi = {
      name = "5G Modeemi";
      host = nodes.modeemi;
      port = 80;
      dashy = {
        section = "verkon hallinta";
        description = "Modeemin hallintapaneeli";
        icon = "mdi-router-network";
      };
    };
    mosquitto = {
      host = nodes.kanto;
      port = 8883;
      public = {
        domain = "mqtt.jhakonen.com";
      };
    };
    nas = {
      host = nodes.nas;
      port = 5000;
      dashy = {
        section = "palvelut";
        description = "Synology NAS hallintapaneeli";
        icon = "http://nas:5000/webman/favicon.ico";
      };
    };
    nextcloud = {
      host = nodes.kanto;
      port = 16000;
      dashy = {
        section = "palvelut";
        description = "Verkkolevy";
        icon = "hl-nextcloud";
      };
      public = {
        domain = "nextcloud.jhakonen.com";
        port = 443;
      };
    };
    node-red = {
      host = nodes.kanto;
      port = 1880;
      dashy = {
        section = "palvelut";
        description = "Kotiautomaation ohjelmointi";
        icon = "hl-node-red";
      };
      public = {
        domain = "node-red.jhakonen.com";
        port = 443;
      };
    };
    paperless = {
      host = nodes.kanto;
      port = 12000;
      dashy = {
        section = "palvelut";
        description = "Asiakirjojen hallinta";
        icon = "hl-paperless";
      };
      public = {
        domain = "paperless.jhakonen.com";
        port = 443;
      };
    };
    reititin = {
      host = nodes.asus-router;
      port = 80;
      dashy = {
        section = "verkon hallinta";
        description = "Reititimen hallintapaneeli";
        icon = "hl-asus-router";
      };
    };
    skanneri-ads-1700w = {
      host = nodes.ads-1700w;
      port = 80;
      dashy = {
        section = "verkon hallinta";
        title = "Brother ADS-1700W";
        description = "Skannerin hallintapaneeli";
        icon = "mdi-barcode-scan";
      };
    };
    sunshine-webui = {
      host = nodes.mervi;
      port = 47990;
      https = true;
      dashy = {
        section = "viihde";
        title = "Sunshine";
        description = "Sunshine pelipalvelimen hallintapaneeli";
        icon = "https://raw.githubusercontent.com/LizardByte/Sunshine/68ba1db24ab66df63fd525d15f95b95bc958beac"
             + "/src_assets/common/assets/web/images/favicon.ico";
      };
    };
    syncthing-dellxps13 = {
      host = nodes.dellxps13;
      port = 8384;
      dashy = {
        section = "syncthing";
        description = "Syncthing - Dell XPS 13";
        icon = "hl-syncthing";
      };
    };
    syncthing-kanto = {
      host = nodes.kanto;
      port = 8384;
      dashy = {
        section = "syncthing";
        description = "Syncthing - kanto";
        icon = "hl-syncthing";
      };
    };
    syncthing-mervi = {
      host = nodes.mervi;
      port = 8384;
      dashy = {
        section = "syncthing";
        description = "Syncthing - Mervi";
        icon = "hl-syncthing";
      };
    };
    syncthing-nas = {
      host = nodes.nas;
      port = 8384;
      dashy = {
        section = "syncthing";
        description = "Syncthing - NAS";
        icon = "hl-syncthing";
      };
    };
    tinypilot = {
      host = nodes.tinypilot;
      port = 443;
      dashy = {
        section = "verkon hallinta";
        title = "Tinypilot";
        description = "Tinypilot etähallinta";
        icon = "hl-tinypilot";
      };
    };
    tulostin-hl-l2445dw = {
      host = nodes.hl-l2445dw;
      port = 80;
      dashy = {
        section = "verkon hallinta";
        title = "Brother HL-L2445DW";
        description = "Tulostimen hallintapaneeli";
        icon = "hl-printer";
      };
    };
    tvheadend-webui = {
      host = nodes.mervi;
      port = 9981;
      dashy = {
        section = "viihde";
        title = "Tvheadend";
        description = "Tvheadend palvelimen hallintapaneeli";
        icon = "hl-tvheadend";
      };
    };
    zigbee2mqtt = {
      host = nodes.toukka;
      port = 8880;
      dashy = {
        section = "palvelut";
        description = "Zigbee modeemin hallintapaneeli";
        icon = "hl-zigbee2mqtt";
      };
      public = {
        domain = "zigbee2mqtt.jhakonen.com";
        port = 443;
      };
    };
  };

  syncthing-devices = {
    "dellxps13".id = "WKELG45-M6XHPMK-LDYP7FI-AIWMZKK-P6ORZHW-KS3KTNL-GPYKNGX-ZBYIGQX";
    "mervi".id = "7BTJFDZ-XDJS5OX-FSBRLIB-PB7ACKK-3VEYRHA-LP5NKYN-KWLZ3QS-X2V36AR";
    "nas".id = "M5AL6GA-OEENQ5G-JN36HDW-M2KBKGB-TCEZIVL-EQXRGZX-BJRJZ4C-MX36TAL";
  };
}
