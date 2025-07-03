{ config, flake, inputs, lib, perSystem, pkgs, ... }:
let
  regreet-init = pkgs.writeShellScript "regreet-init" ''
    set +e
    ${lib.getExe pkgs.kanshi} --config ${kanshi-config} &
    ${lib.getExe config.programs.regreet.package}
  '';

  kanshi-config = pkgs.writeText "kanshi-greeter-config" ''
    profile ulkoinen-naytto {
      output eDP-1 disable
      output DP-1 enable
    }

    profile lapparin-naytto {
      output eDP-1 enable
    }
  '';

  # https://wiki.hyprland.org/Hypr-Ecosystem/hyprpaper/#using-this-keyword-to-randomize-your-wallpaper
  switch-wallpaper = pkgs.writeShellScriptBin "switch-wallpaper" ''
    WALLPAPER_DIR="$HOME/Kuvat/Taustakuvat/ultrawide"
    CURRENT_WALL=$(hyprctl hyprpaper listloaded)

    # Get a random wallpaper that is not the current one
    WALLPAPER=$(find "$WALLPAPER_DIR" -type f ! -name "$(basename "$CURRENT_WALL")" | shuf -n 1)

    # Apply the selected wallpaper
    hyprctl hyprpaper reload ,"$WALLPAPER"
  '';
in {
  # https://search.nixos.org/options?show=programs.regreet
  programs.regreet = {
    enable = true;
    package = pkgs.greetd.regreet.overrideAttrs (o: {
      patches = (o.patches or [ ]) ++ [
        # https://github.com/rharish101/ReGreet/pull/81
        ../../data/regreet-pull-81-rebased.diff
      ];
    });
    iconTheme.package = pkgs.yaru-remix-theme;
    iconTheme.name = "Yaru-remix-light";
    theme.package = pkgs.flat-remix-gtk;
    theme.name = "Flat-Remix-GTK-Yellow-Dark";
    # https://github.com/rharish101/ReGreet/blob/main/regreet.sample.toml
    settings = {
      background.path = "${pkgs.hyprland}/share/hypr/wall2.png";
      background.fit = "Cover";
      skip_selection = true;  # https://github.com/rharish101/ReGreet/pull/81
    };
  };
  services.greetd.settings.default_session.command = "${pkgs.dbus}/bin/dbus-run-session ${lib.getExe pkgs.cage} ${lib.escapeShellArgs config.programs.regreet.cageArgs} -- ${regreet-init}";

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  nixpkgs.overlays = [ inputs.hyprpanel.overlay ];

  environment.systemPackages = with pkgs; [
    brightnessctl  # Läppärin näytön kirkkauden säätö
    kitty
    wofi
    playerctl
    hyprpanel
    myxer
    switch-wallpaper

    adwaita-icon-theme  # Hyprpanel: Sisältää osan puuttuvista ikoneista
    wf-recorder         # Hyprpanel: Videon nauhoitus
    grimblast           # Hyprpanel: Kuvan kaappaus

    kdePackages.qtwayland
    kdePackages.qtsvg

    # KWallet tuki
    kdePackages.kcmutils  # kwalletmanagerin riippuvuus
    kdePackages.kwallet
    kdePackages.kwalletmanager

    # Artwork + themes
    kdePackages.breeze
    kdePackages.breeze-icons
    kdePackages.breeze-gtk
  ];

  fonts.packages = with pkgs; [
    hack-font
    liberation_ttf
    noto-fonts
    noto-fonts-emoji
    nerd-fonts.jetbrains-mono  # hyprpanel
  ];
  fonts.fontconfig.defaultFonts = {
    monospace = [
      "Hack"
      "Noto Sans Mono"
    ];
    sansSerif = [ "Noto Sans" ];
    serif = [ "Noto Serif" ];
  };

  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  xdg.icons.enable = true;
  xdg.icons.fallbackCursorThemes = [ "breeze_cursors" ];

  security.pam.services = {
    greetd.kwallet = {
      enable = true;
      package = pkgs.kdePackages.kwallet-pam;
    };
  };
}
