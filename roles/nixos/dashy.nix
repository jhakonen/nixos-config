# Lähde: https://github.com/jdheyburn/nixos-configs/blob/5175593745a27de7afc5249bc130a2f1c5edb64c/modules/dashy/default.nix
{ config, pkgs, lib, catalog, ... }:

with lib;

let
  version = "2.1.1";

  cfg = config.roles.dashy;

  format = pkgs.formats.yaml { };

  # Start to build the elements in sections, this is then used to discover in catalog.services
  sections = [
    {
      name = "Palvelut";
      icon = "fas fa-cube";
    }
  ];

  # Build the items (services) for each section
  sectionServices = let
    isDashyService = section_name: svc_def:
      svc_def ? "dashy" && svc_def.dashy ? "section" && svc_def.dashy.section
      == section_name;

    createSectionItems = services:
      map (service: {
        title = service.serviceName;
        description = service.dashy.description;
        url = "http://${service.host.hostName}:${toString service.port}";
        icon = service.dashy.icon;
        target = "workspace";
      }) services;

    sectionItems = sectionName:
      createSectionItems (attrValues (filterAttrs
        (svc_name: svc_def: isDashyService (toLower sectionName) svc_def)
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
  options.roles.dashy = { enable = mkEnableOption "enable dashy"; };

  config = mkIf cfg.enable {

    virtualisation.oci-containers.containers.dashy = {
      image = "lissy93/dashy:${version}";
      volumes = [ "${configFile}:/app/public/conf.yml" ];
      ports = [ "${toString catalog.services.dashy.port}:80" ];
    };
  };
}