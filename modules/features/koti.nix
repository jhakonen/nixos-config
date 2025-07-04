{
  flake.modules.nixos.koti = { pkgs, ... }: let
    koti = pkgs.callPackage ../../packages/koti/koti.nix { };
  in {
    # Tätä salaisuutta käytetään koti-työkalusta
    age.secrets.jhakonen-rsyncbackup-password = {
      file = ../../agenix/rsyncbackup-password.age;
      owner = "jhakonen";
    };

    environment.systemPackages = [ koti ];
    programs.zsh = {
      enableBashCompletion = true;
      interactiveShellInit = ''
        source ${koti}/share/bash-completion/completions/koti
      '';
    };
  };
}
