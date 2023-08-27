{ pkgs, ... }:
{
  # Lisää ZSH valittavien komentotulkkien listaan
  environment.shells = [ pkgs.zsh ];

  # Aseta käytettävä komentotulkki
  # Komentotulkki pitää olla environment.shells listassa
  users.defaultUserShell = pkgs.zsh;

  # Tämä vaaditaan kun zsh on lisätty environment.shells listalle
  programs.zsh.enable = true;
}
