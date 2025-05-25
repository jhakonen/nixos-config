{ pkgs, ... }:
{
  home.packages = [ pkgs.fastfetch ];
  programs.zsh = {
    initContent = ''
      fastfetch
    '';
  };
}
