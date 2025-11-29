{ lib, self, ... }:
{
  flake.modules.nixos.common = { config, pkgs, ... }: {
    imports = [
      self.modules.nixos.zsh
    ];

    # Aika-alueen asetus
    time.timeZone = "Europe/Helsinki";

    # Määrittele kieliasetukset
    i18n.defaultLocale = "fi_FI.UTF-8";
    i18n.extraLocaleSettings = {
      LC_ADDRESS = "fi_FI.UTF-8";
      LC_IDENTIFICATION = "fi_FI.UTF-8";
      LC_MEASUREMENT = "fi_FI.UTF-8";
      LC_MONETARY = "fi_FI.UTF-8";
      LC_NAME = "fi_FI.UTF-8";
      LC_NUMERIC = "fi_FI.UTF-8";
      LC_PAPER = "fi_FI.UTF-8";
      LC_TELEPHONE = "fi_FI.UTF-8";
      LC_TIME = "fi_FI.UTF-8";
    };

    # Configure keymap in X11
    services.xserver.xkb = {
      layout = "fi";
      variant = "nodeadkeys";
    };

    # Configure console keymap
    console.keyMap = "fi";

    # Asenna locate ja updatedb komennot, updatedb ajetaan myös kerran päivässä
    # keskiyöllä
    services.locate = {
      enable = true;
      package = pkgs.plocate;
    };

    services.openssh = {
      enable = true;
      settings = {
        # Vaadi SSH sisäänkirjautuminen käyttäen vain yksityistä avainta
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };

    environment.systemPackages = with pkgs; [
      btop
      comma
      fastfetch
      file
      git
      inetutils  # telnet
      inotify-info
      isd
      jq
      killall
      kitty
      lazygit
      nh
      usbutils   # lsusb
      binutils   # strings
      python3
      silver-searcher
      tailspin   # https://github.com/bensadeh/tailspin
      eza        # https://github.com/eza-community/eza
      doggo      # https://doggo.mrkaran.dev/docs/
      nvd        # listaa erot kahden nixos sukupolven väliltä
      wget
    ];

    # Estä `inetutils` pakettia korvaamasta `nettools`
    # paketin ohjelmia `ifconfig`, `hostname` ja `dnsdomainname`
    nixpkgs.config.packageOverrides = pkgs: {
      nettools = lib.hiPrio pkgs.nettools;
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

    environment.shellAliases = {
      lg = "lazygit";
      ls = "eza";
      ll = "eza -l";
      scp = "scp -O";  # Synology NAS ei tue scp:n uudempaa sftp protokollaa
    };

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
    imports = [
      self.modules.homeManager.zsh
    ];

    programs.autojump.enable = true;
    programs.tealdeer = {
      enable = true;
      settings = {
        updates.auto_update = true;
      };
    };
  };
}
