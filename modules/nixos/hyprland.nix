{ config, lib, perSystem, pkgs, ... }:
{
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };
  programs.waybar = {
    enable = true;
    #package = perSystem.nixpkgs-unstable.waybar;
  };
  users.users.jhakonen.extraGroups = [
    "input"  # waybar
  ];
  services.power-profiles-daemon.enable = true;

  # nixpkgs.overlays = [
  #   (final: prev: {
  #     kdePackages = prev.kdePackages.overrideScope (
  #       kfinal: kprev: {
  #         kwallet-pam = kprev.kwallet-pam.overrideAttrs (oldAttrs: {
  #           patches = (oldAttrs.patches or [ ]) ++ [
  #             ./kwallet-pam.patch
  #           ];
  #         });
  #       }
  #     );
  #   })
  # ];

  systemd.user.services.waybar.path = [
    pkgs.pavucontrol  # waybar pulseaudio moduuli tarvitsee tämän
    # (pkgs.python3.withPackages (python-pkgs: [
    #   python-pkgs.pygobject3  # waybar custom/media
    # ]))
    pkgs.python3
    pkgs.playerctl  # waybar custom/media
    pkgs.gobject-introspection
    pkgs.python3Packages.pygobject3
  ];

  environment.systemPackages = (with pkgs; [
    kitty
    dunst
    #qt5-wayland
    #qt6-wayland
    wofi
    pkgs.kdePackages.dolphin
    #kdePackages.plasma-pa
    pavucontrol

  ]) ++ (with pkgs.kdePackages; [
    qtwayland # Hack? To make everything run on Wayland
    qtsvg # Needed to render SVG icons

    # Frameworks with globally loadable bits
    frameworkintegration # provides Qt plugin
    kauth # provides helper service
    kcoreaddons # provides extra mime type info
    kded # provides helper service
    kfilemetadata # provides Qt plugins
    kguiaddons # provides geo URL handlers
    kiconthemes # provides Qt plugins
    kimageformats # provides Qt plugins
    qtimageformats # provides optional image formats such as .webp and .avif
    kio # provides helper service + a bunch of other stuff
    kio-admin # managing files as admin
    kio-extras # stuff for MTP, AFC, etc
    kio-fuse # fuse interface for KIO
    kpackage # provides kpackagetool tool
    kservice # provides kbuildsycoca6 tool
    kunifiedpush # provides a background service and a KCM
    kwallet # provides helper service
    kwallet-pam # provides helper service
    kwalletmanager # provides KCMs and stuff
    plasma-activities # provides plasma-activities-cli tool
    solid # provides solid-hardware6 tool
    phonon-vlc # provides Phonon plugin

    # Core Plasma parts
    kwin
    kscreen
    libkscreen
    kscreenlocker
    kactivitymanagerd
    kde-cli-tools
    kglobalacceld # keyboard shortcut daemon
    kwrited # wall message proxy, not to be confused with kwrite
    baloo # system indexer
    milou # search engine atop baloo
    kdegraphics-thumbnailers # pdf etc thumbnailer
    polkit-kde-agent-1 # polkit auth ui
    plasma-desktop
    plasma-workspace
    drkonqi # crash handler
    kde-inotify-survey # warns the user on low inotifywatch limits

    # Application integration
    libplasma # provides Kirigami platform theme
    plasma-integration # provides Qt platform theme
    kde-gtk-config # syncs KDE settings to GTK

    # Artwork + themes
    breeze
    breeze-icons
    breeze-gtk
    ocean-sound-theme
    plasma-workspace-wallpapers
    pkgs.hicolor-icon-theme # fallback icons
    qqc2-breeze-style
    qqc2-desktop-style

    # misc Plasma extras
    kdeplasma-addons
    pkgs.xdg-user-dirs # recommended upstream

    # Plasma utilities
    kmenuedit
    kinfocenter
    plasma-systemmonitor
    ksystemstats
    libksysguard
    systemsettings
    kcmutils

    plasma-browser-integration
    konsole
    (lib.getBin qttools) # Expose qdbus in PATH
    ark
    elisa
    gwenview
    okular
    kate
    khelpcenter
    dolphin
    baloo-widgets # baloo information in Dolphin
    dolphin-plugins
    spectacle
    ffmpegthumbs
    krdp
    xwaylandvideobridge # exposes Wayland windows to X11 screen capture

    bluedevil
    bluez-qt
    pkgs.openobex
    pkgs.obexftp
  ]);




  qt.enable = true;
  programs.xwayland.enable = true;


  environment.pathsToLink = [
    # FIXME: modules should link subdirs of `/share` rather than relying on this
    "/share"
    "/libexec" # for drkonqi
  ];

  environment.etc."X11/xkb".source = config.services.xserver.xkb.dir;

  # Add ~/.config/kdedefaults to XDG_CONFIG_DIRS for shells, since Plasma sets that.
  # FIXME: maybe we should append to XDG_CONFIG_DIRS in /etc/set-environment instead?
  environment.sessionVariables.XDG_CONFIG_DIRS = [ "$HOME/.config/kdedefaults" ];

  # Needed for things that depend on other store.kde.org packages to install correctly,
  # notably Plasma look-and-feel packages (a.k.a. Global Themes)
  #
  # FIXME: this is annoyingly impure and should really be fixed at source level somehow,
  # but kpackage is a library so we can't just wrap the one thing invoking it and be done.
  # This also means things won't work for people not on Plasma, but at least this way it
  # works for SOME people.
  environment.sessionVariables.KPACKAGE_DEP_RESOLVERS_PATH = "${pkgs.kdePackages.frameworkintegration.out}/libexec/kf6/kpackagehandlers";

  # Enable GTK applications to load SVG icons
  programs.gdk-pixbuf.modulePackages = [ pkgs.librsvg ];

  fonts.packages = [
    pkgs.noto-fonts
    pkgs.hack-font
  ];
  fonts.fontconfig.defaultFonts = {
    monospace = [
      "Hack"
      "Noto Sans Mono"
    ];
    sansSerif = [ "Noto Sans" ];
    serif = [ "Noto Serif" ];
  };

  programs.gnupg.agent.pinentryPackage = lib.mkDefault pkgs.pinentry-qt;
  programs.kde-pim.enable = lib.mkDefault true;
  programs.ssh.askPassword = lib.mkDefault "${pkgs.kdePackages.ksshaskpass.out}/bin/ksshaskpass";

  # Enable helpful DBus services.
  services.accounts-daemon.enable = true;
  # when changing an account picture the accounts-daemon reads a temporary file containing the image which systemsettings5 may place under /tmp
  systemd.services.accounts-daemon.serviceConfig.PrivateTmp = false;

  #services.power-profiles-daemon.enable = lib.mkDefault true;
  services.system-config-printer.enable = lib.mkIf config.services.printing.enable (lib.mkDefault true);
  services.udisks2.enable = true;
  services.upower.enable = config.powerManagement.enable;
  services.libinput.enable = lib.mkDefault true;

  # Extra UDEV rules used by Solid
  services.udev.packages = [
    # libmtp has "bin", "dev", "out" outputs. UDEV rules file is in "out".
    pkgs.libmtp.out
    pkgs.media-player-info
  ];

  # Set up Dr. Konqi as crash handler
  systemd.packages = [ pkgs.kdePackages.drkonqi ];
  systemd.services."drkonqi-coredump-processor@".wantedBy = [ "systemd-coredump@.service" ];

  xdg.icons.enable = true;
  xdg.icons.fallbackCursorThemes = lib.mkDefault [ "breeze_cursors" ];

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [
    pkgs.kdePackages.kwallet
    pkgs.kdePackages.xdg-desktop-portal-kde
    pkgs.xdg-desktop-portal-gtk
  ];
  xdg.portal.configPackages = lib.mkDefault [ pkgs.kdePackages.plasma-workspace ];
  services.pipewire.enable = lib.mkDefault true;

  # Enable screen reader by default
  services.orca.enable = lib.mkDefault true;

  services.displayManager = {
    sessionPackages = [ pkgs.kdePackages.plasma-workspace ];
    defaultSession = lib.mkDefault "plasma";
  };
  services.displayManager.sddm = {
    package = pkgs.kdePackages.sddm;
    theme = lib.mkDefault "breeze";
    #wayland = lib.mkDefault {
    #  enable = true;
    #  compositor = "kwin";
    #};
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
    kde = {
      allowNullPassword = true;
      kwallet = {
        enable = true;
        package = pkgs.kdePackages.kwallet-pam;
      };
    };
    kde-fingerprint = lib.mkIf config.services.fprintd.enable { fprintAuth = true; };
    kde-smartcard = lib.mkIf config.security.pam.p11.enable { p11Auth = true; };
  };

  security.wrappers = {
    kwin_wayland = {
      owner = "root";
      group = "root";
      capabilities = "cap_sys_nice+ep";
      source = "${lib.getBin pkgs.kdePackages.kwin}/bin/kwin_wayland";
    };
  };

  programs.dconf.enable = true;

  programs.firefox.nativeMessagingHosts.packages = [ pkgs.kdePackages.plasma-browser-integration ];

  programs.chromium = {
    enablePlasmaBrowserIntegration = true;
    plasmaBrowserIntegrationPackage = pkgs.kdePackages.plasma-browser-integration;
  };

  programs.kdeconnect.package = pkgs.kdePackages.kdeconnect-kde;
  programs.partition-manager.package = pkgs.kdePackages.partitionmanager;

  # FIXME: ugly hack. See #292632 for details.
  #system.userActivationScripts.rebuildSycoca = activationScript;
  #systemd.user.services.nixos-rebuild-sycoca = {
  #  description = "Rebuild KDE system configuration cache";
  #  wantedBy = [ "graphical-session-pre.target" ];
  #  serviceConfig.Type = "oneshot";
  #  script = activationScript;
  #};





















}