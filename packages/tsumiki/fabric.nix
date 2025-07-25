{
  lib,
  pkg-config,
  wrapGAppsHook3,
  gobject-introspection,
  python3,
  python3Packages,
  runtimeShell,
  gtk3,
  gtk-layer-shell,
  cairo,
  libdbusmenu-gtk3,
  gdk-pixbuf,
  cinnamon-desktop,
  gnome-bluetooth,
  fetchFromGitHub,
  click,
  pycairo,
  pygobject3,
  pygobject-stubs,
  loguru,
  psutil,
  setuptools,
  buildPythonPackage,
}:
buildPythonPackage {
  pname = "python-fabric";
  version = "0.0.2";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "Fabric-Development";
    repo = "fabric";
    rev = "27037055701557e42220a99d562439b918136bd6";
    hash = "sha256-jw6NfobEUbsm3NmBgVUHMk2cWAvD+naRjlRLemO5Z3E=";
  };

  build-system = [ setuptools ];

  nativeBuildInputs = [
    pkg-config
    gobject-introspection
    wrapGAppsHook3
  ];

  buildInputs = [
    gtk3
    gtk-layer-shell
    cairo
    gobject-introspection
    libdbusmenu-gtk3
    gdk-pixbuf
    cinnamon-desktop
    gnome-bluetooth
  ];

  dependencies = [
    click
    pycairo
    pygobject3
    pygobject-stubs
    loguru
    psutil
  ];
}
