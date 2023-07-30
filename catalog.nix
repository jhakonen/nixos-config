# Perustuu ideaan blogista: https://jdheyburn.co.uk/blog/automating-service-configurations-with-nixos/
{ ... }:
let
  addHostNames = nodes: builtins.mapAttrs (hostName: node: node // { "hostName" = hostName; }) nodes;
  addServiceNames = services: builtins.mapAttrs (serviceName: service: service // { "serviceName" = serviceName; }) services;
in rec {
  nodes = addHostNames {
    dellxps13 = {};
    nas-toolbox = {
      ip.private = "192.168.1.171";
    };
  };

  services = addServiceNames {
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
    influxdb = {
      host = nodes.nas-toolbox;
      port = 8086;
    };
    mosquitto = {
      host = nodes.nas-toolbox;
      port = 8883;
      dns.public = "mqtt.jhakonen.com";
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
  };
}
