{ pkgs, ... }:
{
  programs.kodi = {
    enable = true;
    package = (pkgs.kodi.withPackages (exts: [
      exts.netflix
      exts.youtube
      (exts.callPackage ../../packages/kodi-addons/plugin.video.twitch { })
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
      name = "kodi-youtube-set-api-id";
      runtimeInputs = [ pkgs.xmlstarlet ];
      text = ''
        read -rp "Youtube API Id: " api_id
        xmlstarlet edit --inplace --update "/settings/setting[@id='youtube.api.id']" --value "$api_id" \
          "$HOME/.kodi/userdata/addon_data/plugin.video.youtube/settings.xml"
      '';
    })
    (pkgs.writeShellApplication {
      name = "kodi-youtube-set-api-secret";
      runtimeInputs = [ pkgs.xmlstarlet ];
      text = ''
        read -rp "Youtube API Secret: " api_secret
        xmlstarlet edit --inplace --update "/settings/setting[@id='youtube.api.secret']" --value "$api_secret" \
          "$HOME/.kodi/userdata/addon_data/plugin.video.youtube/settings.xml"
      '';
    })
    (pkgs.writeShellApplication {
      name = "kodi-youtube-set-api-key";
      runtimeInputs = [ pkgs.xmlstarlet ];
      text = ''
        read -rp "Youtube API key: " api_key
        xmlstarlet edit --inplace --update "/settings/setting[@id='youtube.api.key']" --value "$api_key" \
          "$HOME/.kodi/userdata/addon_data/plugin.video.youtube/settings.xml"
      '';
    })
    (pkgs.writeShellApplication {
      name = "kodi-twitch-set-oauth-token";
      runtimeInputs = [ pkgs.xmlstarlet ];
      text = ''
        read -rp "Twitch OAuth token: " token
        xmlstarlet edit --inplace --update "/settings/setting[@id='oauth_token_helix']" --value "$token" \
          "$HOME/.kodi/userdata/addon_data/plugin.video.twitch/settings.xml"
      '';
    })
  ];
}
