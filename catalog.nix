# Perustuu ideaan blogista: https://jdheyburn.co.uk/blog/automating-service-configurations-with-nixos/
{ ... }:
let
  addHostNames = nodes: builtins.mapAttrs (hostName: node: { hostName = hostName; } // node) nodes;
  addServiceNames = services: builtins.mapAttrs (serviceName: service: { name = serviceName; } // service) services;
in rec {
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
    nas-ubuntu-vm = {
      ip.private = "192.168.1.70";
    };
    nas-nextcloud-vm = {
      ip.private = "192.168.1.49";
    };
  };

  services = addServiceNames {
    bitwarden = {
      host = nodes.nas;
      port = 443;
      dns.public = "bitwarden.jhakonen.com";
      dashy = {
        section = "palvelut";
        description = "Salasanojen hallinta";
        icon = "hl-bitwarden";
        newTab = true;
      };
    };
    cops = {
      host = nodes.nas;
      port = 443;
      dns.public = "cops.jhakonen.com";
      dashy = {
        section = "palvelut";
        description = "Calibre OPDS palvelin";
        icon = "https://github.com/seblucas/cops/blob/master/images/icons/icon114.png?raw=true";
        newTab = true;
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
    };
    huginn = {
      host = nodes.nas;
      port = 80;
      dns.public = "huginn.jhakonen.com";
      dashy = {
        section = "palvelut";
        description = "Tehtävien automatisointi";
        icon = "hl-huginn";
        newTab = true;
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
      dns.public = "mqtt.jhakonen.com";
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
      host = nodes.nas;
      port = 443;
      dns.public = "nextcloud.jhakonen.com";
      dashy = {
        section = "palvelut";
        description = "Verkkolevy";
        icon = "hl-nextcloud";
        newTab = true;
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
      host = nodes.nas;
      port = 443;
      dns.public = "paperless.jhakonen.com";
      dashy = {
        section = "palvelut";
        description = "Asiakirjojen hallinta";
        icon = "hl-paperless";
        newTab = true;
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
