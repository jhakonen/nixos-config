# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)

{ inputs, osConfig, lib, config, pkgs, ... }:
let
  inherit (osConfig.dep-inject) agenix catalog nur private;
in
{
  imports = [
    ../../roles/home-manager/firefox.nix
    ../../roles/home-manager/git.nix
    ../../roles/home-manager/mqtt-client.nix
    ../../roles/home-manager/neofetch.nix
    ../../roles/home-manager/zsh.nix
    agenix.homeManagerModules.age
    nur.modules.homeManager.default
  ];

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
        ];
      };
    };
  };

  age.secrets = {
    github-id-rsa = {
      file = private.secret-files.github-id-rsa;
      path = "/home/jhakonen/.ssh/github-id-rsa";
    };
    jhakonen-mosquitto-password = {
      file = private.secret-files.mqtt-password;
    };
  };

  accounts.email.accounts = private.catalog.emailAccounts;
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

  services.easyeffects = {
    enable = true;
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";

  # https://nixos.wiki/wiki/Home_Manager#Usage_on_non-NixOS_Linux
  targets.genericLinux.enable = true;

  roles.git.githubIdentityFile = config.age.secrets.github-id-rsa.path;
  roles.mqtt-client.passwordFile = config.age.secrets.jhakonen-mosquitto-password.path;

  my.programs.firefox.enable = true;
}
