{ buildKodiAddon, fetchFromGitHub }:

buildKodiAddon rec {
  pname = "Estuary Nexus Mod (pkscout)";
  namespace = "skin.estuary.nexus.pkscout.mod";
  version = "1.3.9";

  src = fetchFromGitHub {
    owner = "pkscout";
    repo = namespace;
    rev = "main";
    sha256 = "sha256-0mLQ72sMr3Qvxs66tdqA+MqY6GWE5iAgsgRbnUhS7HM=";
  };
}
