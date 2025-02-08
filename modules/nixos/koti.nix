{ perSystem, ... }:
{
  environment.systemPackages = [ perSystem.self.koti.package ];
  programs.zsh = {
    enableBashCompletion = true;
    interactiveShellInit = ''
      source ${perSystem.self.koti.package}/share/bash-completion/completions/koti
    '';
  };
}
