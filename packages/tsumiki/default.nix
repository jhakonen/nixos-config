{
  callPackage,
  cinnamon-desktop,
  dart-sass,
  fetchFromGitHub,
  gnome-bluetooth,
  gobject-introspection,
  gtk-layer-shell,
  gtk3,
  lib,
  libdbusmenu-gtk3,
  librsvg,
  makeWrapper,
  networkmanager,
  playerctl,
  python3,
  stdenv,
}: let
  python-deps = python-pkgs:
    let
      python-fabric = python-pkgs.callPackage ./fabric.nix {};
      pyproject-metadata-0-7-1 = python-pkgs.callPackage ./pyproject-metadata-0-7-1.nix {};
      py-build-cmake = python-pkgs.callPackage ./py-build-cmake.nix {
        inherit pyproject-metadata-0-7-1;
      };
      rlottie-python = python-pkgs.callPackage ./rlottie-python.nix {
        inherit py-build-cmake;
      };
    in [
      python-fabric
      rlottie-python
      python-pkgs.click
      python-pkgs.ijson
      python-pkgs.pillow
      python-pkgs.pyjson5
      python-pkgs.pytomlpp
      python-pkgs.qrcode
      python-pkgs.requests
      python-pkgs.setproctitle
    ];
  python-with-deps = (python3.withPackages python-deps);
in stdenv.mkDerivation rec {
  pname = "tsumiki";
  version = (builtins.fromTOML (builtins.readFile "${src}/pyproject.toml")).project.version;
  src = fetchFromGitHub {
    owner = "jhakonen";
    repo = "Tsumiki";
    rev = "5d191837a43dd8b16d35e247ded13c6fee1047d6";
    hash = "sha256-rE5L+tYunNRI1f/xmUwxuvCfeoeikm54gKIzF+Aprck=";
  };
  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [
    (callPackage ./gray.nix {})
    python-with-deps

    cinnamon-desktop  # libcvc riippuvuus
    dart-sass
    gnome-bluetooth
    gobject-introspection
    gtk-layer-shell
    gtk3
    libdbusmenu-gtk3
    librsvg
    networkmanager
    playerctl
  ];
  postPatch = ''
    substituteInPlace main.py \
      --replace-fail "dist/main.css" "/var/tmp/tsumiki/main.css"
    substituteInPlace utils/config.py \
      --replace-fail "../styles/_settings.scss" "/var/tmp/tsumiki/_settings.scss"
    substituteInPlace main.py \
      --replace-fail "helpers.copy_theme" "# helpers.copy_theme"
  '';
  postInstall = ''
    mkdir -p $out/bin $out/share/tsumiki
    cp -r . $out/share/tsumiki
    makeWrapper ${lib.getExe python-with-deps} $out/bin/tsumiki \
      --add-flag $out/share/tsumiki/main.py \
      --prefix PATH : ${lib.makeBinPath buildInputs} \
      --set GI_TYPELIB_PATH "$GI_TYPELIB_PATH" \
      --set LC_TIME "en_US.UTF-8" \
      --chdir $out/share/tsumiki
  '';
}
