{ pkgs, ... }:
{
  home.packages = [ pkgs.fastfetch ];
  programs.zsh = {
    initExtraFirst = ''
      fastfetch
    '';
  };
}
