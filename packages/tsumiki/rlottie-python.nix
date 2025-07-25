{
  buildPythonPackage,
  cmake,
  fetchPypi,
  py-build-cmake,
}:
buildPythonPackage rec {
  pname = "rlottie_python";
  version = "1.3.7";
  src = fetchPypi {
    inherit pname version;
    hash = "sha256-/hhLGjQCBg1Lu1nv2cE0Uk+jf2xM/KnrYz1ij+rOZzM=";
  };
  nativeBuildInputs = [ cmake ];
  pyproject = true;
  build-system = [ py-build-cmake ];
  pypaBuildFlags = [ ".." ];
}
