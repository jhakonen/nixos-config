{ callPackage, buildKodiAddon, fetchFromGitHub, requests }:
buildKodiAddon rec {
  pname = "Yle Areena";
  namespace = "plugin.video.yleareena.jade";
  version = "1.3.0";

  src = fetchFromGitHub {
    owner = "aajanki";
    repo = namespace;
    rev = "v${version}";
    sha256 = "sha256-wKxgvij/4woVWGMXpKNdrf77OgbCsPfXSaotAeugqN0=";
  };

  propagatedBuildInputs = [
    requests
    (callPackage ./script.module.html5lib.nix { })
    (callPackage ./script.module.webencodings.nix { })
  ];
}
