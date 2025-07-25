{
  fetchFromGitHub,
  glib,
  gobject-introspection,
  gtk3,
  libdbusmenu-gtk3,
  meson,
  ninja,
  pkg-config,
  stdenv,
  vala,
}:
stdenv.mkDerivation {
  pname = "libgray";
  version = "0.1";
  src = fetchFromGitHub {
    owner = "Fabric-Development";
    repo = "gray";
    rev = "main";
    hash = "sha256-s9v9fkp+XrKqY81Z7ezxMikwcL4HHS3KvEwrrudJutw=";
  };

  outputs = ["out" "dev"];

  nativeBuildInputs = [
    gobject-introspection
    meson
    pkg-config
    ninja
    vala
  ];

  buildInputs = [
    glib
    libdbusmenu-gtk3
    gtk3
  ];
}
