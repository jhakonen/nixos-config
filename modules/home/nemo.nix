{ config, flake, pkgs, ... }:
{
  dconf.settings."org/cinnamon/desktop/applications/terminal" = {
    exec = "kitty";
  };
  gtk.enable = true;
  gtk.gtk3.bookmarks = [
    "davs://${flake.lib.catalog.nextcloud-user}@nextcloud.jhakonen.com/remote.php/dav/files/${flake.lib.catalog.nextcloud-user} Nextcloud"
    "file://${config.xdg.userDirs.documents}"
    "file://${config.xdg.userDirs.download}"
    "file://${config.xdg.userDirs.music}"
    "file://${config.xdg.userDirs.pictures}"
    "file://${config.xdg.userDirs.publicShare}"
    "file://${config.xdg.userDirs.templates}"
    "file://${config.xdg.userDirs.videos}"
  ];
  xdg.configFile."gtk-3.0/bookmarks".force = true;
  xdg.mimeApps.defaultApplications = {
    "application/x-gnome-saved-search" = "nemo.desktop";
    "inode/directory" = "nemo.desktop";
  };
}
