{ config, ... }:
let
  inherit (config) catalog;
in
{
  den.default.nixos = { config, lib, pkgs, ... }: {
    options.my.services.restic.backups = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {};
    };

    config = lib.mkIf (config.my.services.restic.backups != {}) {
      age.secrets.restic-password = {
        file = ../../agenix/restic-password.age;
      };
      age.secrets.restic-nas-smb-config = {
        file = ../../agenix/restic-nas-smb-config.age;
      };
      age.secrets.telegram-token = {
        file = ../../agenix/telegram-token.age;
      };

      environment.systemPackages = with pkgs; [
        rclone
        restic
      ];

      # Aseta oletusasetukset kullekin varmuuskopiotehtävälle
      services.restic.backups = builtins.mapAttrs (_name: options:
        {
          initialize = true;
          passwordFile = config.age.secrets.restic-password.path;
          checkOpts = [ "--read-data" ];
          pruneOpts = [
            "--keep-daily 7"
            "--keep-weekly 4"
            "--keep-monthly 12"
            "--keep-yearly 3"
          ];
          rcloneConfigFile = config.age.secrets.restic-nas-smb-config.path;
        } // options
      ) config.my.services.restic.backups;

      systemd.services =
        # Palvelu epäonnistuneesta ajosta ilmoittamiseen
        {
          "notify-failure@" = {
            description = "Ilmoita palvelun %i epäonnistumisesta";
            scriptArgs = "%i";
            path = [ pkgs.shoutrrr ];
            script = ''
              TOKEN=$(cat ${config.age.secrets.telegram-token.path})
              journalctl --unit="$1" --output=cat --invocation=0 --grep "failed|error" --lines=+1 | shoutrrr send \
                --url telegram://$TOKEN@telegram?chats=${catalog.telegramChat} \
                --title "Palvelu $1 epäonnistui" \
                --message -
            '';
          };
        }
        //
        # Lähetä ilmoitus jos varmuuskopiointi epäonnistuu
        (lib.mapAttrs' (name: _options: lib.nameValuePair "restic-backups-${name}" {
          unitConfig.OnFailure = [ "notify-failure@restic-backups-${name}.service" ];
        }) config.my.services.restic.backups);
    };
  };
}
