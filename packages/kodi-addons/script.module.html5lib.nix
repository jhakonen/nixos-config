{ buildKodiAddon, fetchzip }:
buildKodiAddon rec {
  pname = "html5lib";
  namespace = "script.module.html5lib";
  version = "1.1.0+matrix.1";

  src = fetchzip {
    url = "https://mirrors.kodi.tv/addons/nexus/${namespace}/${namespace}-${version}.zip";
    sha256 = "sha256-IJqDrCmncTMtkbCBthlukXxQraCBu3uqbcBz3+BxTKk=";
  };
}
