# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)

{ catalog, inputs, outputs, lib, config, pkgs, agenix, ... }: {
  imports = [
    ../../roles/home-manager/git.nix
    ../../roles/home-manager/kde-fix-desktop-files.nix
    ../../roles/home-manager/neofetch.nix
    ../../roles/home-manager/zsh.nix
  ];

  age = {
    secrets = {
      github-id-rsa = {
        file = ../../secrets/github-id-rsa.age;
        path = "/home/jhakonen/.ssh/github-id-rsa";
      };
    };
  };

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      # outputs.overlays.additions
      # outputs.overlays.modifications
      outputs.overlays.unstable-packages

      # You can also add overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      # allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      # allowUnfreePredicate = (_: true);
    };
  };

  home = {
    username = "jhakonen";
    homeDirectory = "/home/jhakonen";
  };

  # Add stuff for your user as you see fit:
  # programs.neovim.enable = true;
  home.packages = [
    agenix.packages."x86_64-linux".default  # agenix komento
    pkgs.calibre
    pkgs.nixos-rebuild  # rebuildaus etäkoneelle
    pkgs.nix-index  # Nixpkgs pakettien sisällön etsiminen
  ];

  # Enable home-manager and git
  programs.home-manager.enable = true;

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "kota" = {
        user = "pi";
      };
      "nas" = {
        user = "valvoja";
        identityFile = [
          "~/.ssh/id_rsa"
          "~/.ssh/id_rsa_borgbackup"
        ];
      };
    };
  };

  accounts.email.accounts = catalog.emailAccounts;
  programs.thunderbird = {
    enable = true;
    package = pkgs.thunderbird;  # Thunderbird 115 paremmalla käyttöliittymällä
    profiles."${config.home.username}" = {
      isDefault = true;
      settings = {
        # Järjestä mailit oletuksena kaikissa kansioissa laskevasti (uusin ensimmäisenä)
        "mailnews.default_sort_order" = 2;
      };
    };
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";

  # https://nixos.wiki/wiki/Home_Manager#Usage_on_non-NixOS_Linux
  targets.genericLinux.enable = true;

  roles.git.githubIdentityFile = config.age.secrets.github-id-rsa.path;
}
