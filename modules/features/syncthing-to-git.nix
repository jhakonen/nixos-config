{ self, ... }:
let
  inherit (self) catalog;
in
{
  flake.modules.nixos.syncthing-to-git = { config, pkgs, ... }: let
    mkPushToGitService = args: {
      path = [
        pkgs.git
        pkgs.openssh
      ];
      # Kokeile ajaa komentoja root/syncthing käyttäjänä
      # cd /var/lib/syncthing/Muistiinpanot
      # sudo -u root -g syncthing bash -c "GIT_SSH_COMMAND=\"ssh -i '/run/agenix/kanto-gitea-ssh-key'\" git remote show origin"
      script = ''
        export GIT_SSH_COMMAND="ssh -i '${config.age.secrets.kanto-gitea-ssh-key.path}'"
        cd ${args.dir}
        git add --all
        if git commit --message 'Varmuuskopio'; then
          git push origin main
        fi
      '';
      # Joka päivä, mutta ei samaan aikaan kun Gitea on alhaalla
      # varmuuskopioinnin takia
      startAt = "02:30:00";
      serviceConfig = {
        User = "root";
        Group = "syncthing";
      };
    };
  in {
    age.secrets.kanto-gitea-ssh-key.file = ../../agenix/kanto-gitea-ssh-key.age;

    systemd.services."muistiinpanot-to-git" = mkPushToGitService {
      dir = catalog.paths.syncthing.muistiinpanot;
    };
    systemd.services."paivakirja-to-git" = mkPushToGitService {
      dir = catalog.paths.syncthing.paivakirja;
    };
  };
}
