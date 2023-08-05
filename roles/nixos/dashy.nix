# Lähde: https://github.com/jdheyburn/nixos-configs/blob/5175593745a27de7afc5249bc130a2f1c5edb64c/modules/dashy/default.nix
{ pkgs, lib, catalog, ... }:
let
  version = "2.1.1";

  format = pkgs.formats.yaml { };

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

  getServiceTarget = service:
    if (service ? dashy.newTab && service.dashy.newTab) then
      "newtab"
    else
      "workspace"
    ;

  # Build the items (services) for each section
  sectionServices = let
    isDashyService = section_name: svc_def:
      svc_def ? "dashy" && svc_def.dashy ? "section" && svc_def.dashy.section
      == section_name;

    createSectionItems = services:
      map (service: {
        title = catalog.getServiceName(service);
        description = service.dashy.description;
        url = "${catalog.getServiceScheme service}://${catalog.getServiceAddress service}:${toString (catalog.getServicePort service)}";
        icon = service.dashy.icon;
        target = getServiceTarget service;
      }) services;

    sectionItems = sectionName:
      createSectionItems (lib.attrValues (lib.filterAttrs
        (svc_name: svc_def: isDashyService (lib.toLower sectionName) svc_def)
        catalog.services));

  in map (section: section // { items = sectionItems section.name; }) sections;

  dashyConfig = {
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

    sections = sectionServices;
  };

  configFile = format.generate "dashy.yaml" dashyConfig;

in {
  virtualisation.oci-containers.containers.dashy = {
    image = "lissy93/dashy:${version}";
    volumes = [ "${configFile}:/app/public/conf.yml" ];
    ports = [ "${toString catalog.services.dashy.port}:80" ];
  };
}
