{ config, inputs, lib, perSystem, pkgs, ... }:
{
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  nixpkgs.overlays = [ inputs.hyprpanel.overlay ];

  users.users.jhakonen.extraGroups = [
    "input"  # waybar
  ];
  services.power-profiles-daemon.enable = true;

  environment.systemPackages = (with pkgs; [
    kitty
    wofi
    playerctl
    hyprpanel
    myxer

    # Hyprpanel tarvitsee tämän
    pkgs.adwaita-icon-theme

  ]) ++ (with pkgs.kdePackages; [
    qtwayland # Hack? To make everything run on Wayland
    qtsvg # Needed to render SVG icons
    dolphin

    # KWallet tuki
    kwallet
    kwallet-pam  # Tarjoaa skriptin /run/current-system/sw/libexec/pam_kwallet_init
    kwalletmanager # provides KCMs and stuff

    plasma-desktop # TARVITAAN JOTTA SDDM EI NÄYTÄ RIKKINÄISELTÄ

    # Artwork + themes
    breeze
    breeze-icons
    breeze-gtk
  ]);

  qt.enable = true;
  programs.xwayland.enable = true;

  environment.pathsToLink = [
    "/libexec" # kwallet
  ];

  # Enable GTK applications to load SVG icons
  programs.gdk-pixbuf.modulePackages = [ pkgs.librsvg ];

  fonts.packages = with pkgs; [
    fira-code
    fira-code-symbols
    font-awesome
    hack-font
    liberation_ttf
    mplus-outline-fonts.githubRelease
    noto-fonts
    noto-fonts-emoji
    proggyfonts
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

  # programs.gnupg.agent.pinentryPackage = lib.mkDefault pkgs.pinentry-qt;
  # programs.kde-pim.enable = lib.mkDefault true;
  # programs.ssh.askPassword = lib.mkDefault "${pkgs.kdePackages.ksshaskpass.out}/bin/ksshaskpass";

  # Enable helpful DBus services.
  services.accounts-daemon.enable = true;
  # when changing an account picture the accounts-daemon reads a temporary file containing the image which systemsettings5 may place under /tmp
  systemd.services.accounts-daemon.serviceConfig.PrivateTmp = false;

  # services.system-config-printer.enable = lib.mkIf config.services.printing.enable (lib.mkDefault true);
  # services.udisks2.enable = true;

  # ####### Hyprpanel tarvitsee tämän
  services.upower.enable = true;

  # services.libinput.enable = lib.mkDefault true;

  # Extra UDEV rules used by Solid
  services.udev.packages = [
    # libmtp has "bin", "dev", "out" outputs. UDEV rules file is in "out".
    pkgs.libmtp.out
    pkgs.media-player-info
  ];

  xdg.icons.enable = true;
  xdg.icons.fallbackCursorThemes = lib.mkDefault [ "breeze_cursors" ];

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [
    pkgs.kdePackages.kwallet
    pkgs.kdePackages.xdg-desktop-portal-kde
    pkgs.xdg-desktop-portal-gtk
  ];
  xdg.portal.configPackages = lib.mkDefault [ pkgs.kdePackages.plasma-workspace ];

  services.displayManager.sddm = {
    package = pkgs.kdePackages.sddm;
    theme = lib.mkDefault "breeze";
    extraPackages = with pkgs.kdePackages; [
      breeze-icons
      kirigami
      libplasma
      plasma5support
      qtsvg
      qtvirtualkeyboard
    ];
  };

  security.pam.services = {
    login.kwallet = {
      enable = true;
      package = pkgs.kdePackages.kwallet-pam;
    };
  };
}