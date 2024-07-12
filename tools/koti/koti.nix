{
  bash,
  bashly,
  coreutils,
  gnugrep,
  installShellFiles,
  iputils,
  ncurses,
  resholve,
}:
# https://github.com/nixos/nixpkgs/blob/master/pkgs/development/misc/resholve/README.md
resholve.mkDerivation rec {
  pname = "koti";
  version = "0.1.0";
  src = ./.;

  nativeBuildInputs = [
    bashly
    installShellFiles
  ];

  buildPhase = ''
    runHook preBuild
    KOTI_VERSION="${version}" bashly generate
    bashly add completions_script
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp koti $out/bin
    installShellCompletion --name koti completions.bash
    runHook postInstall
  '';

  solutions = {
    default = {
      fake.external = [ "nix" "subl" ];
      fix.ping = true;
      interpreter = "${bash}/bin/bash";
      inputs = [
        # koti-skriptin ajonaikaiset riippuvuudet
        coreutils
        gnugrep
        iputils
        ncurses
      ];
      scripts = [ "bin/koti" ];
    };
  };
}
