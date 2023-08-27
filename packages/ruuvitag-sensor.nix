{ bluez, fetchPypi, python3 }:

python3.pkgs.buildPythonPackage rec {
  pname = "ruuvitag-sensor";
  version = "2.1.0";
  src = fetchPypi {
    pname = "ruuvitag_sensor";
    inherit version;
    sha256 = "sha256-I+wSS5E1yUTYBulTQ+5v9x2qRpmizbK59Wx25QcGsCY=";
  };
  format = "pyproject";

  nativeBuildInputs = [
    python3.pkgs.setuptools
  ];

  propagatedBuildInputs = with python3.pkgs; [
    ptyprocess
    reactivex
  ];
}
