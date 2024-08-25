{ buildKodiAddon, fetchFromGitHub }:

buildKodiAddon rec {
  pname = "Estuary Nexus Mod (pkscout)";
  namespace = "skin.estuary.pkscout.mod";
  version = "21.0.5";

  src = fetchFromGitHub {
    owner = "pkscout";
    repo = namespace;
    rev = "omega";
    sha256 = "sha256-hK1lpjzwL+OMssg3vRiOldewWtmIfAGpUDDG0zlHMlw=";
  };
}
