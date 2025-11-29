{ lib, self, ... }: let
  inherit (self) catalog;
in {
  flake.modules.homeManager.git = { config, ... }: let
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
        settings = {
          alias.l = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
          init.defaultBranch = "main";
          user = {
            name = "Janne Hakonen";
            email = catalog.githubEmail;
          };
        };
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
  };
}
