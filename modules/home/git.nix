{ config, inputs, lib, osConfig, ... }:
let
  cfg = config.roles.git;
in {
  options.roles.git = {
    githubIdentityFile = lib.mkOption {
      type = lib.types.str;
    };
  };

  config.programs = {
    git = {
      enable = true;
      userName = "Janne Hakonen";
      userEmail = inputs.private.catalog.githubEmail;
      aliases.l = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      extraConfig.init.defaultBranch = "main";
    };
    ssh = {
      enable = true;
      matchBlocks = {
        "framagit.org" = {
          identityFile = "~/.ssh/framagit-ssh-key";
          user = "git";
        };
        "github.com" = {
          identityFile = cfg.githubIdentityFile;
          user = "git";
        };
      };
    };
  };
}
