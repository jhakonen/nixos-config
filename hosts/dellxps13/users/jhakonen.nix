{ config, flake, inputs, lib, osConfig, perSystem, pkgs, ... }:
{
  imports = [
    flake.modules.home.common
    flake.modules.home.firefox
    flake.modules.home.git
    flake.modules.home.kanshi
    flake.modules.home.mqtt-client
    flake.modules.home.nemo
    flake.modules.home.systeminfo
    inputs.agenix.homeManagerModules.age
    inputs.nur.modules.homeManager.default

    # Hyprland modules
    flake.modules.home.hyprland-home
  ];

  # Add stuff for your user as you see fit:
  # programs.neovim.enable = true;
  home.packages = [
    perSystem.agenix.default  # agenix komento
    pkgs.calibre
    pkgs.nixos-rebuild  # rebuildaus etäkoneelle
    pkgs.nix-index  # Nixpkgs pakettien sisällön etsiminen
  ];

  # Enable home-manager and git
  programs.home-manager.enable = true;

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "kota" = {
        user = "pi";
      };
      "nas" = {
        user = "valvoja";
        identityFile = [
          "~/.ssh/id_rsa"
        ];
      };
    };
  };

  age.secrets = {
    github-id-rsa = {
      file = ../../../agenix/github-id-rsa.age;
      path = "/home/jhakonen/.ssh/github-id-rsa";
    };
    jhakonen-mosquitto-password = {
      file = ../../../agenix/mqtt-password.age;
    };
  };

  accounts.email.accounts = flake.lib.catalog.emailAccounts;
  programs.thunderbird = {
    enable = true;
    package = pkgs.thunderbird;  # Thunderbird 115 paremmalla käyttöliittymällä
    profiles."${config.home.username}" = {
      isDefault = true;
      settings = {
        # Järjestä mailit oletuksena kaikissa kansioissa laskevasti (uusin ensimmäisenä)
        "mailnews.default_sort_order" = 2;
      };
    };
  };

  services.easyeffects = {
    enable = true;
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";

  # https://nixos.wiki/wiki/Home_Manager#Usage_on_non-NixOS_Linux
  targets.genericLinux.enable = true;

  roles.git.githubIdentityFile = config.age.secrets.github-id-rsa.path;
  roles.mqtt-client.passwordFile = config.age.secrets.jhakonen-mosquitto-password.path;

  my.programs.firefox.enable = true;

  # https://wiki.nixos.org/wiki/Default_applications
  # Tiedostotyypin näkee komennolla "file -i <tiedoston polku>"
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/pdf" = "org.kde.okular.desktop";
      "text/html" = "firefox.desktop";
      "text/markdown" = "sublime_text.desktop";
      "video/mp4" = "vlc.desktop";
      "video/webm" = "vlc.desktop";
      "x-scheme-handler/about" = "firefox.desktop";
      "x-scheme-handler/element" = "Beeper.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/mailto" = "thunderbird.desktop";
      "x-scheme-handler/unknown" = "firefox.desktop";
    };
  };

  xdg.userDirs = {
    enable = true;
    desktop = "${config.home.homeDirectory}/Työpöytä";
    documents = "${config.home.homeDirectory}/Asiakirjat";
    download = "${config.home.homeDirectory}/Lataukset";
    music = "${config.home.homeDirectory}/Musiikki";
    pictures = "${config.home.homeDirectory}/Kuvat";
    publicShare = "${config.home.homeDirectory}/Julkinen";
    templates = "${config.home.homeDirectory}/Mallit";
    videos = "${config.home.homeDirectory}/Videot";
  };

  gtk.theme = {
    package = pkgs.flat-remix-gtk;
    # Mahdolliset teemojen nimet löytää komennolla:
    #   ll $(nix eval --raw nixpkgs#flat-remix-gtk.outPath)/share/themes/
    name = "Flat-Remix-GTK-Yellow-Dark";
  };
  gtk.iconTheme = {
    package = pkgs.yaru-remix-theme;
    # Mahdolliset teemojen nimet löytää komennolla:
    #   ll $(nix eval --raw nixpkgs#yaru-remix-theme.outPath)/share/icons/
    name = "Yaru-remix-light";
  };
}
