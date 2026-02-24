{ lib, ... }:
{
  den.ctx.host.nixos = { pkgs, ... }: {
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

  den.default.homeManager = { pkgs, ... }: {
    programs.zsh = {
      enable = true;
      autosuggestion.enable = true;

      # Ota completion tuki pois päältä jotta HM ei heitä järjestelmätason
      # completion asetuksia roskiin
      enableCompletion = false;

      initContent = ''
        # Kopioitu osoitteesta https://wiki.archlinux.org/title/Zsh#Key_bindings
        typeset -g -A key

        key[Home]="''${terminfo[khome]}"
        key[End]="''${terminfo[kend]}"
        key[Insert]="''${terminfo[kich1]}"
        key[Backspace]="''${terminfo[kbs]}"
        key[Delete]="''${terminfo[kdch1]}"
        key[Up]="''${terminfo[kcuu1]}"
        key[Down]="''${terminfo[kcud1]}"
        key[Left]="''${terminfo[kcub1]}"
        key[Right]="''${terminfo[kcuf1]}"
        key[PageUp]="''${terminfo[kpp]}"
        key[PageDown]="''${terminfo[knp]}"
        key[Shift-Tab]="''${terminfo[kcbt]}"

        [[ -n "''${key[Home]}"      ]] && bindkey -- "''${key[Home]}"       beginning-of-line
        [[ -n "''${key[End]}"       ]] && bindkey -- "''${key[End]}"        end-of-line
        [[ -n "''${key[Insert]}"    ]] && bindkey -- "''${key[Insert]}"     overwrite-mode
        [[ -n "''${key[Backspace]}" ]] && bindkey -- "''${key[Backspace]}"  backward-delete-char
        [[ -n "''${key[Delete]}"    ]] && bindkey -- "''${key[Delete]}"     delete-char
        [[ -n "''${key[Up]}"        ]] && bindkey -- "''${key[Up]}"         up-line-or-history
        [[ -n "''${key[Down]}"      ]] && bindkey -- "''${key[Down]}"       down-line-or-history
        [[ -n "''${key[Left]}"      ]] && bindkey -- "''${key[Left]}"       backward-char
        [[ -n "''${key[Right]}"     ]] && bindkey -- "''${key[Right]}"      forward-char
        [[ -n "''${key[PageUp]}"    ]] && bindkey -- "''${key[PageUp]}"     beginning-of-buffer-or-history
        [[ -n "''${key[PageDown]}"  ]] && bindkey -- "''${key[PageDown]}"   end-of-buffer-or-history
        [[ -n "''${key[Shift-Tab]}" ]] && bindkey -- "''${key[Shift-Tab]}"  reverse-menu-complete

        if (( ''${+terminfo[smkx]} && ''${+terminfo[rmkx]} )); then
          autoload -Uz add-zle-hook-widget
          function zle_application_mode_start { echoti smkx }
          function zle_application_mode_stop { echoti rmkx }
          add-zle-hook-widget -Uz zle-line-init zle_application_mode_start
          add-zle-hook-widget -Uz zle-line-finish zle_application_mode_stop
        fi
      '';

      plugins = [
        # Lähde: https://discourse.nixos.org/t/using-an-external-oh-my-zsh-theme-with-zsh-in-nix/6142/4
        {
          name = "powerlevel10k";
          src = pkgs.zsh-powerlevel10k;
          file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
        }
        {
          name = "powerlevel10k-config";
          src = lib.cleanSource ../../data;
          file = ".p10k.zsh";
        }
      ];
    };
  };
}
