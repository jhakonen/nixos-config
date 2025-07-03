{ lib, ... }:
{
  flake.modules.nixos.common = { config, pkgs, ... }: {
    # Asenna locate ja updatedb komennot, updatedb ajetaan myös kerran päivässä
    # keskiyöllä
    services.locate = {
      enable = true;
      package = pkgs.plocate;
    };

    environment.systemPackages = with pkgs; [
      btop
      comma
      file
      git
      inetutils  # telnet
      inotify-info
      isd
      jq
      kitty
      usbutils   # lsusb
      binutils   # strings
      python3
      silver-searcher
      tailspin   # https://github.com/bensadeh/tailspin
      eza        # https://github.com/eza-community/eza
      doggo      # https://doggo.mrkaran.dev/docs/
      nvd        # listaa erot kahden nixos sukupolven väliltä
    ];

    # Estä `inetutils` pakettia korvaamasta `nettools`
    # paketin ohjelmia `ifconfig`, `hostname` ja `dnsdomainname`
    nixpkgs.config.packageOverrides = pkgs: {
      nettools = pkgs.hiPrio pkgs.nettools;
    };

    programs.nix-index.enable = true;
    programs.command-not-found.enable = false;

    # Listaa kaikki asennetut paketit polussa /etc/current-system-packages
    # Lähde: https://www.reddit.com/r/NixOS/comments/fsummx/comment/fm45htj/
    environment.etc."current-system-packages".text = lib.pipe config.environment.systemPackages [
      (builtins.map (p: "${p.name}"))
      lib.unique
      (builtins.sort builtins.lessThan)
      (builtins.concatStringsSep "\n")
    ];

    # Listaa muuttuneet paketit nixos-rebuild komennon lopussa. Otettu täältä:
    #   https://discourse.nixos.org/t/nvd-simple-nix-nixos-version-diff-tool/12397/42
    system.activationScripts.preActivation = ''
      if [[ -e /run/current-system ]]; then
        echo "--- diff to current-system"
        ${pkgs.nvd}/bin/nvd --nix-bin-dir=${config.nix.package}/bin \
          diff /run/current-system "$systemConfig"
        echo "---"
      fi
    '';
  };

  flake.modules.homeManager.common = { pkgs, ... }: {
    programs.autojump.enable = true;

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
      shellAliases = {
        ls = "eza";
        ll = "eza -l";
        scp = "scp -O";  # Synology NAS ei tue scp:n uudempaa sftp protokollaa
      };
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

    programs.tealdeer = {
      enable = true;
      settings = {
        updates.auto_update = true;
      };
    };
  };
}
