{ config, flake, inputs, lib, osConfig, perSystem, pkgs, ... }:
{
  imports = [
    flake.modules.home.firefox
    flake.modules.home.git
    flake.modules.home.mqtt-client
    flake.modules.home.systeminfo
    flake.modules.home.zsh
    inputs.agenix.homeManagerModules.age
    inputs.nur.modules.homeManager.default
  ];

  # Add stuff for your user as you see fit:
  # programs.neovim.enable = true;
  home.packages = [
    perSystem.agenix.default  # agenix komento
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
      file = ../../../agenix/github-id-rsa.age;
      path = "/home/jhakonen/.ssh/github-id-rsa";
    };
    jhakonen-mosquitto-password = {
      file = ../../../agenix/mqtt-password.age;
    };
  };

  accounts.email.accounts = flake.lib.catalog.emailAccounts;
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
