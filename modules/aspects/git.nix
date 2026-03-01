{
  den.aspects."jhakonen@dellxps13".homeManager = { config, ... }: {
    age.secrets.github-id-rsa = {
      file = ../../agenix/github-id-rsa.age;
      path = "/home/jhakonen/.ssh/github-id-rsa";
    };

    programs = {
      git = {
        enable = true;
        settings = {
          alias.l = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
          init.defaultBranch = "main";
          user = {
            name = "Janne Hakonen";
            email = config.catalog.githubEmail;
          };
        };
      };
      ssh = {
        enable = true;
        enableDefaultConfig = false;
        matchBlocks = {
          "framagit.org" = {
            identityFile = "~/.ssh/framagit-ssh-key";
            user = "git";
          };
          "github.com" = {
            identityFile = config.age.secrets.github-id-rsa.path;
            user = "git";
          };
        };
      };
    };
  };
}
