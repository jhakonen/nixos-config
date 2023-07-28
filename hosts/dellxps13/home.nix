# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)

{ inputs, outputs, lib, config, pkgs, agenix, ... }: {
  # You can import other home-manager modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/home-manager):
    # outputs.homeManagerModules.example

    # Or modules exported from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModules.default

    # You can also split up your configuration and import pieces of it here:
    # ./nvim.nix

    ../../roles/home-manager
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
      # outputs.overlays.unstable-packages

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
    pkgs.nixos-rebuild  # rebuildaus etäkoneelle
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
      "nas-ubuntu-vm" = {
        user = "jhakonen";
      };
    };
  };

  programs.bash = {
    enable = true;
    bashrcExtra = ''
      # Promptin tyyli
      source /etc/bashrc
    '';
    # profileExtra = ''
    #   if [ -e /home/jhakonen/.nix-profile/etc/profile.d/nix.sh ]; then . /home/jhakonen/.nix-profile/etc/profile.d/nix.sh; fi
    # '';
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";

  roles.git = {
    enable = true;
    githubIdentityFile = config.age.secrets.github-id-rsa.path;
  };
  roles.neofetch.enable = true;
}