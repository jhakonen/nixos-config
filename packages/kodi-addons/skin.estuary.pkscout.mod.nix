{ buildKodiAddon, fetchFromGitHub }:

buildKodiAddon rec {
  pname = "Estuary Nexus Mod (pkscout)";
  namespace = "skin.estuary.pkscout.mod";
  version = "21.0.5";

  src = fetchFromGitHub {
    owner = "pkscout";
    repo = namespace;
    rev = "omega";
    sha256 = "sha256-IXV8/7fEuSGVav85M1+FaAifjAxWK/1iLmaUc7d4Ia0=";
  };
}
