{ pkgs, ... }:
{
  home.packages = [ pkgs.neofetch ];
  programs.zsh = {
    initExtraFirst = ''
      neofetch
    '';
  };
}
