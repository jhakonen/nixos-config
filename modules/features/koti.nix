{
  flake.modules.nixos.koti = { pkgs, ... }: let
    koti = pkgs.callPackage ../../packages/koti/koti.nix { };
  in {
    environment.systemPackages = [ koti ];
    programs.zsh = {
      enableBashCompletion = true;
      interactiveShellInit = ''
        source ${koti}/share/bash-completion/completions/koti
      '';
    };
  };
}
