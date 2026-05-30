{
  den.aspects.dellxps13.provides.jhakonen.homeManager = { config, ... }: {
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
        settings = {
          "framagit.org" = {
            IdentityFile = "~/.ssh/framagit-ssh-key";
            User = "git";
          };
          "github.com" = {
            IdentityFile = config.age.secrets.github-id-rsa.path;
            User = "git";
          };
        };
      };
    };
  };
}
