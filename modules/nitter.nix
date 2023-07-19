{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.apps.nitter;
in {
  options.apps.nitter = {
    enable = mkEnableOption "Nitter app";
  };

  config = mkIf cfg.enable {
    services.nitter = {
      enable = true;
      openFirewall = true;
      server = {
        port = 11000;
        hostname = "nitter.jhakonen.com";
      };
    };
    # 14.7.2023: Käännä Nitterin uusin master jossa on search fixi mukana
    nixpkgs.overlays = [(final: prev: {
      nitter = prev.nitter.overrideAttrs (old: {
        src = prev.fetchFromGitHub {
          owner = "zedeus";
          repo = "nitter";
          rev = "afbdbd293e30f614ee288731717868c6d618b55f";
          hash = "sha256-sbhc/R/QlShsnM30BhlWc/NWPBr5MJwxfF57JeBQygQ=";
        };
      });
    })];
  };
}
