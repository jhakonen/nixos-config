{ config, pkgs, ... }:
let
  koti = (pkgs.callPackage .../../../../tools/koti {}).package;
in
{
  environment.systemPackages = [ koti ];
  programs.zsh = {
    enableBashCompletion = true;
    interactiveShellInit = ''
      source ${koti}/share/bash-completion/completions/koti
    '';
  };
}
