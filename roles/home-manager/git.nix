{ lib, config, ... }:
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
      userEmail = "***REMOVED***";
      aliases.l = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
    };
    ssh = {
      enable = true;
      matchBlocks."github.com" = {
        identityFile = cfg.githubIdentityFile;
        user = "git";
      };
    };
  };
}
