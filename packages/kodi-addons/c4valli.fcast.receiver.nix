{ buildKodiAddon, fetchFromGitHub, zip }:

buildKodiAddon {
  pname = "Kodi FCast Receiver";
  namespace = "c4valli.fcast.receiver";
  version = "1.0.0";

  buildInputs = [
    zip
  ];

  src = fetchFromGitHub {
    owner = "c4valli";
    repo = "kodi-fcast-receiver";
    rev = "main";
    sha256 = "sha256-2u5Fvj6qBQDKQsQF7v+797DSE1lCR3LQ+a2atCgl9Kw=";
  };
}
