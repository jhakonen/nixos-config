# Tämä lisää kursorin piilottavan työpöytätehosteen KDE:n. Tämä on hyödyllinen Mervissä jossa
# hiiren kursori ei enää piiloudu automaattisesti Kodissa, ellei kursoria siirrä ensin johonkin
# suuntaan, mikä on vaikeaa ilman oikea hiirtä.
# Tämä tehoste tulee KDE 6.1 versiossa sisäänrakennettuna, mutta tämä erillinen lisäosa tarvitaan
# KDE 6.0 versiossa.
{ cmake
, kdePackages
, stdenv
, fetchFromGitHub
}:
stdenv.mkDerivation rec {
  pname = "hidecursor";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "jinliu";
    repo = "kwin-effect-hide-cursor";
    rev = "master";
    sha256 = "sha256-HtEF7wVDjV9heQxC0feZJ8LyuU+qw0Hyj/uX7ueYh9k=";
  };
  nativeBuildInputs = [ cmake kdePackages.wrapQtAppsHook ];
  buildInputs = [ kdePackages.kwin ];
}
