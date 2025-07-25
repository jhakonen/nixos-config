{
  buildPythonPackage,
  click,
  distlib,
  fetchPypi,
  lark,
  pyproject-metadata-0-7-1,
}:
buildPythonPackage rec {
  pname = "py_build_cmake";
  version = "0.4.3";
  src = fetchPypi {
    inherit pname version;
    hash = "sha256-o3ghRs+AlcERhcd8csHi6Fgq8H254H/4QGkcU8ParJo=";
  };
  pyproject = true;
  build-system = [];
  dependencies = [
    click
    distlib
    lark
    pyproject-metadata-0-7-1
  ];
  dontConfigure = true;
}
