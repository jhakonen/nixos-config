# Lähde: https://github.com/jdheyburn/nixos-configs/blob/5175593745a27de7afc5249bc130a2f1c5edb64c/modules/dashy/default.nix
{ pkgs, lib, catalog, ... }:
let
  # Start to build the elements in sections, this is then used to discover in catalog.services
  sections = [
    {
      name = "Palvelut";
      icon = "fas fa-cube";
    }
    {
      name = "Verkon hallinta";
      icon = "fas fa-router";
    }
  ];

  getSectionItems = sectionName: services:
    map buildSectionItem (getServicesInSection sectionName services);

  getServicesInSection = sectionName: services:
    lib.attrValues (lib.filterAttrs (_: service: isInDashySection sectionName service) services);

  isInDashySection = sectionName: service:
    service ? dashy.section && service.dashy.section == (lib.toLower sectionName);

  buildSectionItem = service: {
    title = catalog.getServiceName(service);
    description = service.dashy.description;
    url = "${catalog.getServiceScheme service}://${catalog.getServiceAddress service}:${toString (catalog.getServicePort service)}";
    icon = service.dashy.icon;
    target = getServiceTarget service;
  };

  getServiceTarget = service:
    if (service ? dashy.newTab && service.dashy.newTab) then
      "newtab"
    else
      "workspace"
    ;
in {
  services.dashy = {
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
        layout = "vertical";
        preventWriteToDisk = true;
        preventLocalSave = true;
        disableConfiguration = false;
        disableContextMenu = true;
        hideComponents = {
          hideSettings = true;
          hideFooter = true;
        };
        workspaceLandingUrl = "home-assistant";
      };
      sections = map (section: section // { items = getSectionItems section.name catalog.services; }) sections;
    };
  };
}
