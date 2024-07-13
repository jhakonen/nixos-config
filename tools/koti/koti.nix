{
  bash,
  bashly,
  coreutils,
  ets,
  findutils,
  gnugrep,
  installShellFiles,
  iputils,
  ncurses,
  nettools,
  openssh,
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
      execer = [
        "cannot:${openssh}/bin/ssh-keygen"
        "cannot:${openssh}/bin/ssh-keyscan"

        # Ei pidä paikkaansa, 'ets' ajaa sille annetun komennon. Mutta
        # valehdellaan nyt että se ei pysty ajamaan komentoja. Tämä vaatisi
        # lore-säännön jotta resholve tietäisi mitä pitää tehdä.
        "cannot:${ets}/bin/ets"
      ];
      fake.external = [ "nix" "subl" ];
      fix.ping = true;
      interpreter = "${bash}/bin/bash";
      inputs = [
        # koti-skriptin ajonaikaiset riippuvuudet
        coreutils
        ets
        findutils
        iputils
        ncurses
        nettools
        openssh
      ];
      scripts = [ "bin/koti" ];
    };
  };
}
