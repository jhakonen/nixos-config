{ lib, ... }:
{
  flake.modules.nixos.zsh = { pkgs, ... }: {
    # Lisää ZSH valittavien komentotulkkien listaan
    environment.shells = [ pkgs.zsh ];

    # Aseta käytettävä komentotulkki
    # Komentotulkki pitää olla environment.shells listassa
    users.defaultUserShell = pkgs.zsh;

    # Tämä vaaditaan kun zsh on lisätty environment.shells listalle
    programs.zsh.enable = true;

    # Ota ZSH käyttöön `nix develop`, 'nix shell' ja `nix-shell` tulkeissa
    # programs.zsh.interactiveShellInit = ''
    #   ${lib.getExe pkgs.nix-your-shell} zsh | source /dev/stdin
    # '';
  };
}
