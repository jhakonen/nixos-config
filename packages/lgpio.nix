# GPIO kirjasto joka toimii rpin kanssa muissakin distroissa kuin Raspbianissa
{ stdenv, fetchFromGitHub, which }:

stdenv.mkDerivation {
  name = "lgpio";
  src = fetchFromGitHub {
    owner = "joan2937";
    repo = "lg";
    rev = "v0.2.2";
    sha256 = "sha256-92lLV+EMuJj4Ul89KIFHkpPxVMr/VvKGEocYSW2tFiE=";
  };
  buildInputs = [ which ];
  installFlags = [ "DESTDIR=${placeholder "out"}" "prefix=" ];
}
