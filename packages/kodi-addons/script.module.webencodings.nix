{ buildKodiAddon, fetchzip }:
buildKodiAddon rec {
  pname = "webencodings";
  namespace = "script.module.webencodings";
  version = "0.5.1+matrix.2";

  src = fetchzip {
    url = "https://mirrors.kodi.tv/addons/nexus/${namespace}/${namespace}-${version}.zip";
    sha256 = "sha256-l6vtB22EnqtBasjGXPJ+1bQ5L/4/5Bp6Ielzu/LU4cI=";
  };
}
