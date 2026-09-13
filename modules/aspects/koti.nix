{
  den.aspects.koti.nixos = { pkgs, ... }: let
    koti = pkgs.callPackage ../../packages/koti/koti.nix { };
    koti-go = pkgs.callPackage ../../packages/koti-go/koti-go.nix { };
  in {
    environment.systemPackages = [ koti koti-go ];
    programs.zsh = {
      enableBashCompletion = true;
      interactiveShellInit = ''
        source ${koti}/share/bash-completion/completions/koti
      '';
    };
  };
}
