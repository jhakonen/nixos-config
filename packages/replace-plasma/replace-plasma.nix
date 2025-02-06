{
  copyDesktopItems,
  coreutils,
  kdePackages,
  lib,
  makeDesktopItem,
  stdenv,
  writeShellApplication,
}:
let
  name = "replace-plasma-shell";
  shell-script = writeShellApplication {
    inherit name;
    runtimeInputs = [
      coreutils
      kdePackages.plasma-workspace
    ];
    text = ''
      nohup plasmashell --replace >/dev/null 2>&1 &
    '';
  };
in
stdenv.mkDerivation {
  pname = "replace-plasma";
  version = "1.0.0";
  dontUnpack = true;  # Tämä mahdolistaa src attribuutin pois jäätämisen
  # Lisää skripti polulle
  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp ${lib.getExe shell-script} $out/bin
    runHook postInstall
  '';
  # Lisää .desktop tiedosto skriptille
  nativeBuildInputs = [ copyDesktopItems ];
  desktopItems = [(makeDesktopItem {
    inherit name;
    desktopName = "Replace Plasma Shell";
    exec = name;
    icon = "process-stop";
  })];
}
