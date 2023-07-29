{ lib, config, pkgs, ... }:
let
  cfg = config.roles.neofetch;
in {
  options.roles.neofetch = {
    enable = lib.mkEnableOption "Neofetch rooli";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.neofetch ];
    programs.zsh = {
      initExtraFirst = ''
        neofetch
      '';
    };
  };
}
