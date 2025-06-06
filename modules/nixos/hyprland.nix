{ config, flake, inputs, lib, perSystem, pkgs, ... }:
{
  imports = [
    flake.modules.nixos.sddm
  ];

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

    adwaita-icon-theme  # Hyprpanel: Sisältää osan puuttuvista ikoneista
    wf-recorder         # Hyprpanel: Videon nauhoitus
    grimblast           # Hyprpanel: Kuvan kaappaus

    kdePackages.qtwayland
    kdePackages.qtsvg

    # KWallet tuki
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
    login.kwallet = {
      enable = true;
      package = pkgs.kdePackages.kwallet-pam;
    };
  };
}