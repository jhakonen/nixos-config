# Lähde: https://github.com/jali-clarke/homelab-config/blob/master/modules/kodi/addons/plugin.video.twitch/default.nix
{ callPackage, buildKodiAddon, fetchFromGitHub, requests, six }:
buildKodiAddon rec {
  pname = "twitch";
  namespace = "plugin.video.twitch";
  version = "3.0.1";

  src = fetchFromGitHub {
    owner = "anxdpanic";
    repo = namespace;
    rev = "v${version}";
    sha256 = "sha256-fF2um1qKylbM1n8o/qfoP41fb+yjS83LZuO9IPWmjBk=";
  };

  propagatedBuildInputs = [
    requests
    six
    (callPackage ./script.module.python.twitch.nix { })
  ];
}
