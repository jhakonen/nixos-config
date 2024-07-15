{
  bashly,
  coreutils,
  ets,
  findutils,
  gawk,
  glibcLocales,
  gnugrep,
  gnused,
  installShellFiles,
  iputils,
  lib,
  makeWrapper,
  ncurses,
  nettools,
  openssh,
  rsync,
  shellcheck-minimal,
  stdenv,
  systemd,
}:
stdenv.mkDerivation rec {
  pname = "koti";
  version = "0.1.0";
  src = ./.;
  doCheck = true;

  nativeBuildInputs = [
    bashly
    glibcLocales
    installShellFiles
    makeWrapper
  ];

  buildPhase = ''
    runHook preBuild
    export LANG=en_US.UTF-8
    export KOTI_VERSION="${version}"
    bashly generate
    bashly add completions_script
    runHook postBuild
  '';

  checkPhase = ''
    runHook preCheck
    ${lib.getExe shellcheck-minimal} koti \
      --exclude=${lib.concatStringsSep "," [
        "SC2154" # https://github.com/DannyBen/bashly/issues/534
      ]}
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp koti $out/bin
    wrapProgram $out/bin/koti \
      --prefix PATH : ${lib.makeBinPath [
          coreutils
          ets
          findutils
          gawk
          gnugrep
          gnused
          iputils
          ncurses
          nettools
          openssh
          rsync
          systemd
        ]}
    installShellCompletion --name koti completions.bash
    runHook postInstall
  '';
}
