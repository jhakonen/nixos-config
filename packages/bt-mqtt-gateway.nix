{ fetchFromGitHub, python3, ruuvitag-sensor }:

python3.pkgs.buildPythonApplication rec {
  pname = "bt-mqtt-gateway";
  version = "1.0.0";
  src = fetchFromGitHub {
    # Sisältää korjauksen:
    #   https://github.com/jhakonen/bt-mqtt-gateway/commit/7dc088ff59c7b8e2242d30065a0d2d1a5726e85e
    owner = "jhakonen";
    repo = "bt-mqtt-gateway";
    rev = "7dc088ff59c7b8e2242d30065a0d2d1a5726e85e";
    sha256 = "sha256-V3cMs2YP4jS5noVzyFdiEr7wTAMLCla6iBv7k/Iqj+A=";
  };
  # src = /home/jhakonen/code/bt-mqtt-gateway;

  propagatedBuildInputs = with python3.pkgs; [
    # Perusriippuvuudet
    apscheduler
    interruptingcow
    paho-mqtt
    pyyaml
    tenacity

    # Ruuvitag-pluginin riippuvuudet
    bluepy ruuvitag-sensor
  ];

  preBuild = ''
# Oletuksena bt-mqtt-gateway lataa logger.yaml tiedoston työskentelyhakemistosta mikä
# nyt voi olla mikätahansa, muuta koodia niin että se lataa tiedoston nix storesta
substituteInPlace logger.py --replace "logger.yaml" "$out/share/logger.yaml"

# Oletuksena bt-mqtt-gateway lataa config.yaml tiedoston samasta kansiosta kuin
# lähdekoodit (nix storesta), mikä estää sen muokkaamisen. Vältä tämä
# lataamalla tiedosto käyttäjän määrittelemästä paikasta
substituteInPlace config.py --replace \
  'os.path.join(os.path.dirname(os.path.realpath(__file__)), "config.yaml")' \
  'os.environ["CONFIG_FILE"]'

# Luo skriptinpätkä jota voi käyttää gateway.py moduulin suorittamiseen setuptoolsin
# entry pointtien kautta.
cat > entrypoint.py << EOF
def execute():
  import gateway
EOF

# Bt-mqtt-gateway projektilla ei ole setup.py skriptiä paketin luomiseen, joten
# luo sellainen jotta se voidaan paketoida Nixiin.
cat > setup.py << EOF
from setuptools import setup

with open('requirements.txt') as f:
  install_requires = f.read().splitlines()

setup(
  name='${pname}',
  version='${version}',
  packages=['hooks', 'workers'],
  py_modules=[
    "config",
    "const",
    "entrypoint",
    "exceptions",
    "gateway",
    "logger",
    "mqtt",
    "utils",
    "workers_manager",
    "workers_queue",
    "workers_requirements",
  ],
  install_requires=install_requires,
  entry_points={
    'console_scripts': [
      # Tämä entrypoint skripti luodaan paketin kansioon polkuun /bin/bt-mqtt-gateway
      'bt-mqtt-gateway=entrypoint:execute'
    ]
  },
)
EOF
  '';

  postInstall = ''
    mkdir -p $out/share
    cp logger.yaml $out/share/
  '';
}
