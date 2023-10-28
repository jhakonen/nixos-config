{ config, lib, pkgs, ... }:
{
  # Make programs installed via this config file have their desktop entries
  # appear in KDE's application launcher
  # Source: https://github.com/nix-community/home-manager/issues/1439#issuecomment-1106208294,
  # but use a folder where desktop files do not have to be in a subfolder, as KDE's launcher
  # does not seem to find files from there
  home.activation = {
    linkDesktopApplications = {
      after = [ "writeBoundary" "createXdgUserDirectories" ];
      before = [ ];
      data = ''
        rm -rf ${config.xdg.dataHome}/nix-desktop-files/applications
        mkdir -p ${config.xdg.dataHome}/nix-desktop-files/applications
        cp -Lr ${config.home.homeDirectory}/.nix-profile/share/applications/* ${config.xdg.dataHome}/nix-desktop-files/applications/
      '';
    };
  };

  xdg.enable = true;
  xdg.systemDirs.data = [ "${config.xdg.dataHome}/nix-desktop-files" ];
}
