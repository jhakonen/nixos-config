{ lib, pkgs, config, ... }:
let
  cfg = config.roles.nitter;
in {
  options.roles.nitter = {
    enable = lib.mkEnableOption "Nitter rooli";
  };

  config = lib.mkIf cfg.enable {
    services.nitter = {
      enable = true;
      openFirewall = true;
      server = {
        port = 11000;
        hostname = "nitter.jhakonen.com";
      };
    };
    # 22.7.2023: Käännä Nitterin uusin master
    nixpkgs.overlays = [(final: prev: {
      nitter = prev.nitter.overrideAttrs (old: {
        src = prev.fetchFromGitHub {
          owner = "zedeus";
          repo = "nitter";
          rev = "72d8f35cd1ec1205824711a41dab4b8d7a6b298a";
          hash = "sha256-EijzAxZdYT7o9IaHZEGTwDfYPAe1W1DtSfUfRHI4AxM=";
        };
      });
    })];
  };
}