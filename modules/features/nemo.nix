{ self, ... }:
let
  inherit (self) catalog;
  mkFileBookmark = path: "file://${path} ${builtins.baseNameOf path}";
in
{
  flake.modules.nixos.nemo = { pkgs, ... }: {
    environment.systemPackages = [
      pkgs.nemo-with-extensions
    ];
    services.gvfs.enable = true;
    # Tämä tarvitaan jotta Nemo näkee kaikki ohjelmat johon tiedoston voi avata
    xdg.mime.enable = true;
  };

  flake.modules.homeManager.nemo = { config, ... }: {
    dconf.settings."org/cinnamon/desktop/applications/terminal" = {
      exec = "kitty";
    };
    gtk.enable = true;
    gtk.gtk3.bookmarks = [
      "davs://${catalog.nextcloud-user}@nextcloud.jhakonen.com/remote.php/dav/files/${catalog.nextcloud-user} Nextcloud"
      "sftp://kanto/var/lib/paperless/media/documents/archive Paperless Media"
      "smb://nas/scans Paperless Syöte"
      (mkFileBookmark config.xdg.userDirs.documents)
      (mkFileBookmark config.xdg.userDirs.download)
      (mkFileBookmark config.xdg.userDirs.music)
      (mkFileBookmark config.xdg.userDirs.pictures)
      (mkFileBookmark config.xdg.userDirs.videos)
      (mkFileBookmark config.xdg.userDirs.publicShare)
      (mkFileBookmark config.xdg.userDirs.templates)
    ];
    xdg.configFile."gtk-3.0/bookmarks".force = true;
    xdg.mimeApps.defaultApplications = {
      "application/x-gnome-saved-search" = "nemo.desktop";
      "inode/directory" = "nemo.desktop";
    };
  };
}
