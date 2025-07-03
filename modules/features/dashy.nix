# Lähde: https://github.com/jdheyburn/nixos-configs/blob/5175593745a27de7afc5249bc130a2f1c5edb64c/modules/dashy/default.nix
{ lib, self, ... }:
let
  inherit (self) catalog;

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
  flake.modules.nixos.dashy = { config, ... }: {
    my.services.dashy = {
      enable = true;
      port = catalog.services.dashy.port;
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

    services.nginx = {
      enable = true;
      virtualHosts.${catalog.services.dashy.public.domain} = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString catalog.services.dashy.port}";
          recommendedProxySettings = true;
        };
        # Käytä Let's Encrypt sertifikaattia
        forceSSL = true;
        useACMEHost = "jhakonen.com";
      };
    };

    # Palvelun valvonta
    my.services.monitoring.checks = [
      {
        type = "systemd service";
        description = "Dashy - container";
        name = config.systemd.services."${config.virtualisation.oci-containers.backend}-dashy".name;
      }
      {
        type = "http check";
        description = "Dashy - web interface";
        secure = true;
        domain = catalog.services.dashy.public.domain;
        response.code = 200;
      }
    ];
  };
}
