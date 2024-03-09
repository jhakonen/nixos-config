{ pkgs, ... }:
{
  programs.kodi = {
    enable = true;
    package = (pkgs.kodi.withPackages (exts: [
      exts.inputstream-adaptive
      #exts.netflix
      exts.pvr-hts  # TVheadend
      exts.youtube
      #(exts.callPackage ../../packages/kodi-addons/plugin.video.twitch { })
      (exts.callPackage ../../packages/kodi-addons/plugin.video.yleareena.jade.nix {})
    ]));
    settings = {};
    sources = {
      video = {
        source = [
          { name = "NAS FTP - Elokuvat"; path = "ftp://media:123456@nas:21/video/Elokuvat/"; allowsharing = "true"; }
          { name = "NAS FTP - Sarjat - Anime"; path = "ftp://media:123456@nas:21/video/Sarjat/Anime/"; allowsharing = "true"; }
          { name = "NAS FTP - Sarjat - Fantasia"; path = "ftp://media:123456@nas:21/video/Sarjat/Fantasia/"; allowsharing = "true"; }
          { name = "NAS FTP - Sarjat - SciFi"; path = "ftp://media:123456@nas:21/video/Sarjat/SciFi/"; allowsharing = "true"; }
          { name = "NAS FTP - Sarjat - Draama"; path = "ftp://media:123456@nas:21/video/Sarjat/Draama/"; allowsharing = "true"; }
        ];
      };
      music = {
        source = [
          { name = "NAS FTP - Oma musiikki"; path = "ftp://media:123456@nas:21/music/Omat/"; allowsharing = "true"; }
          { name = "NAS FTP - Ladatut"; path = "ftp://media:123456@nas:21/music/Muut/"; allowsharing = "true"; }
        ];
      };
    };
  };
  home.packages = [
    (pkgs.writeShellApplication {
      name = "kodi-set-addon-setting";
      runtimeInputs = [ pkgs.xmlstarlet ];
      text = ''
        xmlstarlet edit --inplace --update "/settings/setting[@id='$2']" --value "$3" \
          "$HOME/.kodi/userdata/addon_data/$1/settings.xml"
      '';
    })
    (pkgs.writeShellApplication {
      name = "kodi-youtube-set-api-id";
      text = ''
        read -rp "Youtube API Id: " api_id
        kodi-set-addon-setting plugin.video.youtube youtube.api.id "$api_id"
      '';
    })
    (pkgs.writeShellApplication {
      name = "kodi-youtube-set-api-secret";
      text = ''
        read -rp "Youtube API Secret: " api_secret
        kodi-set-addon-setting plugin.video.youtube youtube.api.secret "$api_secret"
      '';
    })
    (pkgs.writeShellApplication {
      name = "kodi-youtube-set-api-key";
      text = ''
        read -rp "Youtube API key: " api_key
        kodi-set-addon-setting plugin.video.youtube youtube.api.key "$api_key"
      '';
    })
    # (pkgs.writeShellApplication {
    #   name = "kodi-twitch-set-oauth-token";
    #   text = ''
    #     read -rp "Twitch OAuth token: " token
    #     kodi-set-addon-setting plugin.video.twitch oauth_token_helix "$token"
    #   '';
    # })
    # (pkgs.writeShellApplication {
    #   name = "kodi-twitch-set-private-oauth-token";
    #   text = ''
    #     echo "See: https://github.com/anxdpanic/plugin.video.twitch/wiki/Private-API-Credentials---OAuth-Token#2-enabling-additional-features"
    #     read -rp "Twitch private credentials OAuth token: " token
    #     kodi-set-addon-setting plugin.video.twitch private_oauth_token "$token"
    #   '';
    # })
  ];
}
