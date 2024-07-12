{ config, pkgs, ... }:
let
  inherit (config.dep-inject) koti;
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
