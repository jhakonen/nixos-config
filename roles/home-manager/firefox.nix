{ config, lib, pkgs, ... }:
let
  cfg = config.my.programs.firefox;
in {
  options.my.programs.firefox = {
    enable = lib.mkEnableOption "Firefox web browser";
    nur = lib.mkOption { };
  };

  config = lib.mkIf cfg.enable {
    programs.firefox = {
      enable = true;
      profiles.hakonen = {
        extensions = with cfg; [
          nur.repos.rycee.firefox-addons.bitwarden
          nur.repos.rycee.firefox-addons.floccus
          nur.repos.rycee.firefox-addons.multi-account-containers
          nur.repos.rycee.firefox-addons.ublacklist
        ];
        search = {
          force = true;
          default = "StartPage";
          engines = {
            "Stract" = {
              urls = [{
                template = "https://stract.com/search";
                params = [
                  { name = "q"; value = "{searchTerms}"; }
                ];
              }];
              definedAliases = [ "@s" ];
              iconUpdateURL = "https://stract.com/favicon.ico";
            };
            "StartPage" = {
              urls = [{
                template = "https://www.startpage.com/sp/search";
                params = [
                  { name = "query"; value = "{searchTerms}"; }
                ];
              }];
              definedAliases = [ "@sp" ];
              iconUpdateURL = "https://www.startpage.com/favicon.ico";
            };
            "Nix Packages" = {
              urls = [{
                template = "https://search.nixos.org/packages";
                params = [
                  { name = "type"; value = "packages"; }
                  { name = "query"; value = "{searchTerms}"; }
                ];
              }];

              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@np" ];
            };
            "NixOS Wiki" = {
              urls = [{ template = "https://nixos.wiki/index.php?search={searchTerms}"; }];
              iconUpdateURL = "https://nixos.wiki/favicon.png";
              updateInterval = 24 * 60 * 60 * 1000; # every day
              definedAliases = [ "@nw" ];
            };
            "Marginalia" = {
              urls = [{
                template = "https://search.marginalia.nu/search";
                params = [
                  { name = "query"; value = "{searchTerms}"; }
                ];
              }];
              definedAliases = [ "@m" ];
              iconUpdateURL = "https://search.marginalia.nu/favicon.ico";
            };
            "Bing".metaData.hidden = true;
            "Amazon.nl".metaData.hidden = true;
            "Google".metaData.hidden = true;
          };
          order = [ "StartPage" "Nix Packages" ];
        };
        settings = {
          # How to figure out which setting to change:
          # 1. Make a backup of prefs.js:  $ cp ~/.mozilla/firefox/hakonen/{prefs.js,prefs.js.bak}
          # 2. Make a change through Firefox's settings page
          # 3. Compare prefs.js and the backup:  $ meld ~/.mozilla/firefox/hakonen/{prefs.js.bak,prefs.js}
          #
          "browser.backspace_action" = 0;  # Use backspace as back button
          "browser.ctrlTab.sortByRecentlyUsed" = true;  # Ctrl+Tab cycles tabs on previously used basis
          "browser.startup.page" = 3;  # Open previously open windows and tabs on startup
          "browser.tabs.closeWindowWithLastTab" = false; # Älä sulje selainta kun viimeinen välilehti suljetaan
          "privacy.donottrackheader.enabled" = true;
          "privacy.globalprivacycontrol.enabled" = true;
          "privacy.globalprivacycontrol.was_ever_enabled" = true;
          "signon.rememberSignons" = false;  # Do not save usernames and passwords, I have KeepassXC for that
        };
      };
    };
  };
}
