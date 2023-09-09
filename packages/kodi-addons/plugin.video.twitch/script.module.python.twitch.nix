{ callPackage, buildKodiAddon, fetchFromGitHub, requests, six }:
buildKodiAddon rec {
  pname = "script-twitch";
  namespace = "script.module.python.twitch";
  version = "3.0.2";

  src = fetchFromGitHub {
    owner = "anxdpanic";
    repo = namespace;
    rev = "v${version}";
    sha256 = "sha256-dxBL4ZOQ4N/34dgmTcosDjG995zxwywnup2oOSTUV0E=";
  };

  propagatedBuildInputs = [
    requests
    six
  ];
}
