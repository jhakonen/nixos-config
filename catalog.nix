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
  getServiceScheme = service: if (getServicePort service) == 443 then "https" else "http";

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
    kota = {
      ip.private = "192.168.1.132";
    };
    nas = {
      ip.private = "192.168.1.101";
    };
    nas-toolbox = {
      ip.private = "192.168.1.171";
    };
    nas-nextcloud-vm = {
      ip.private = "192.168.1.49";
    };
  };

  services = addServiceNames {
    bitwarden = {
      host = nodes.nas-toolbox;
      port = 10000;
      dashy = {
        section = "palvelut";
        description = "Salasanojen hallinta";
        icon = "hl-bitwarden";
        newTab = true;
      };
      public = {
        domain = "bitwarden.jhakonen.com";
        port = 443;
      };
    };
    cops = {
      host = nodes.nas-nextcloud-vm;
      port = 10000;
      dashy = {
        section = "palvelut";
        description = "Calibre OPDS palvelin";
        icon = "https://github.com/seblucas/cops/blob/master/images/icons/icon114.png?raw=true";
        newTab = true;
      };
      public = {
        domain = "cops.jhakonen.com";
        port = 443;
      };
    };
    dashy = {
      host = nodes.nas-toolbox;
      port = 80;
    };
    grafana = {
      host = nodes.nas-toolbox;
      port = 3000;
      dashy = {
        section = "palvelut";
        description = "Kotiautomaation valvonta";
        icon = "hl-grafana";
      };
    };
    home-assistant = {
      host = nodes.nas-toolbox;
      port = 8123;
      dashy = {
        section = "palvelut";
        description = "Kotiautomaation hallinta";
        icon = "hl-home-assistant";
      };
      public.domain = "kota.jhakonen.com";
    };
    huginn = {
      host = nodes.nas-toolbox;
      port = 14000;
      dashy = {
        section = "palvelut";
        description = "Tehtävien automatisointi";
        icon = "hl-huginn";
        newTab = true;
      };
      public = {
        domain = "huginn.jhakonen.com";
        port = 80;
      };
    };
    influx-db = {
      host = nodes.nas-toolbox;
      port = 8086;
    };
    modeemi = {
      name = "5G Modeemi";
      host = nodes.modeemi;
      port = 80;
      dashy = {
        section = "verkon hallinta";
        description = "Modeemin hallintapaneeli";
        icon = "mdi-router-network";
        newTab = true;
      };
    };
    mosquitto = {
      host = nodes.nas-toolbox;
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
        newTab = true;
      };
    };
    nextcloud = {
      host = nodes.nas-nextcloud-vm;
      port = 80;
      dashy = {
        section = "palvelut";
        description = "Verkkolevy";
        icon = "hl-nextcloud";
        newTab = true;
      };
      public = {
        domain = "nextcloud.jhakonen.com";
        port = 443;
      };
    };
    nitter = {
      host = nodes.nas-toolbox;
      port = 11000;
      dashy = {
        section = "palvelut";
        description = "Twitterin käyttöliittymä";
        icon = "hl-nitter";
      };
      public = {
        domain = "nitter.jhakonen.com";
        port = 80;
      };
    };
    node-red = {
      host = nodes.nas-toolbox;
      port = 1880;
      dashy = {
        section = "palvelut";
        description = "Kotiautomaation ohjelmointi";
        icon = "hl-node-red";
      };
    };
    paperless = {
      host = nodes.nas-toolbox;
      port = 12000;
      dashy = {
        section = "palvelut";
        description = "Asiakirjojen hallinta";
        icon = "hl-paperless";
        newTab = true;
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
        newTab = true;
      };
    };
    zigbee2mqtt = {
      host = nodes.kota;
      port = 8880;
      dashy = {
        section = "palvelut";
        description = "Zigbee modeemin hallintapaneeli";
        icon = "hl-zigbee2mqtt";
      };
    };
  };
}
