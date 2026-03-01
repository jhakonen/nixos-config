# Lähde: https://github.com/jdheyburn/nixos-configs/blob/5175593745a27de7afc5249bc130a2f1c5edb64c/modules/dashy/default.nix
{ lib, config, ... }:
let
  inherit (config) catalog;

  # Start to build the elements in sections, this is then used to discover in catalog.services
  sections = [
    {
      name = "Palvelut";
      icon = "fas fa-cube";
    }
    {
      name = "Syncthing";
      icon = "";
    }
    {
      name = "Valvonta";
      icon = "fab fa-watchman-monitoring";
    }
    {
      name = "Verkon hallinta";
      icon = "fas fa-router";
    }
    {
      name = "Viihde";
      icon = "fas fa-video";
    }
  ];

  getSectionItems = sectionName: services:
    lib.pipe services [
      lib.attrValues
      (builtins.filter (service:
        service ? dashy.section
          && service.dashy.section == (lib.toLower sectionName)
      ))
      (map (service: {
        title = if service ? dashy.title then service.dashy.title else catalog.getServiceName(service);
        description = service.dashy.description;
        url = "${catalog.getServiceScheme service}://${catalog.getServiceAddress service}:${toString (catalog.getServicePort service)}";
        icon = service.dashy.icon;
        target = "newtab";
      }))
    ];
in {
  den.aspects.kanto.nixos = {
    services.dashy = {
      enable = true;
      virtualHost = {
        enableNginx = true;
        domain = catalog.services.dashy.public.domain;
      };
      settings = {
        pageInfo = {
          title = "Koti";
          navLinks = [{
            title = "Dashy Documentation";
            path = "https://dashy.to/docs";
          }];
        };
        appConfig = {
          theme = "nord-frost";
          iconSize = "large";
          layout = "auto";
          preventWriteToDisk = true;
          preventLocalSave = true;
          disableConfiguration = false;
          disableContextMenu = true;
          hideComponents = {
            hideFooter = true;
            hideHeading = true;
            hideNav = true;
            hideSettings = true;
          };
          workspaceLandingUrl = "home-assistant";
        };
        sections = map (section: section // { items = getSectionItems section.name catalog.services; }) sections;
      };
    };

    services.nginx.virtualHosts.${catalog.services.dashy.public.domain} = {
      # Käytä Let's Encrypt sertifikaattia
      forceSSL = true;
      useACMEHost = "jhakonen.com";
    };

    # Palvelun valvonta
    services.gatus.settings.endpoints = [{
      name = "Dashy";
      url = "https://${catalog.services.dashy.public.domain}";
      conditions = [ "[STATUS] == 200" ];
    }];
  };
}
