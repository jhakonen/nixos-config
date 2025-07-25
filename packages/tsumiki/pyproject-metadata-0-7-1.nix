{
  fetchPypi,
  pyproject-metadata,
  setuptools,
}:
pyproject-metadata.overridePythonAttrs (oldAttrs: rec {
  version = "0.7.1";
  src = fetchPypi {
    pname = "pyproject-metadata";
    inherit version;
    hash = "sha256-CpTxixCLmyHzomo9VB8FbDTtyxfchyoUShVhj+1672c=";
  };
  build-system = [ setuptools ];
})
