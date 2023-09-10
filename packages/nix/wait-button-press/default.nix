{ stdenv, lgpio }:

stdenv.mkDerivation {
  name = "wait-button-press";
  src = ./.;

  buildInputs = [ lgpio ];

  buildPhase = ''
    runHook preBuild
    gcc -Wall -o wait-button-press wait-button-press.c -llgpio
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp wait-button-press $out/bin
    runHook postInstall
  '';
}
