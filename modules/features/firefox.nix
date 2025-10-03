{ lib, ... }:
{
  flake.modules.homeManager.firefox = { config, pkgs, ... }: let
    cfg = config.my.programs.firefox;
  in {
    options.my.programs.firefox = {
      enable = lib.mkEnableOption "Firefox web browser";
    };

    config = lib.mkIf cfg.enable {
      programs.firefox = {
        enable = true;
        profiles.hakonen = {
          extensions.packages = with pkgs; [
            nur.repos.rycee.firefox-addons.consent-o-matic
            nur.repos.rycee.firefox-addons.floccus
            nur.repos.rycee.firefox-addons.kagi-search
            nur.repos.rycee.firefox-addons.keepassxc-browser
            nur.repos.rycee.firefox-addons.multi-account-containers
            nur.repos.rycee.firefox-addons.ublacklist
          ];
          search = {
            force = true;
            default = "Kagi";
            engines = {
              "Kagi" = {
                urls = [{
                  template = "https://kagi.com/search?q={searchTerms}";
                }];
                icon = "https://kagi.com/favicon.ico";
                definedAliases = [ "@k" ];
              };
              "StartPage" = {
                urls = [{
                  template = "https://www.startpage.com/sp/search?query={searchTerms}";
                }];
                icon = "https://www.startpage.com/favicon.ico";
                definedAliases = [ "@sp" ];
              };
              "Noogle" = {
                urls = [{
                  template = "https://noogle.dev?term={searchTerms}";
                }];
                icon = "file://${../../data/noogle.png}";
                definedAliases = [ "@nog" ];
              };
              "Nix Packages" = {
                urls = [{
                  template = "https://search.nixos.org/packages?query={searchTerms}";
                }];
                icon = "file://${../../data/nix-packages.png}";
                definedAliases = [ "@np" ];
              };
              "Nix Options" = {
                urls = [{
                  template = "https://search.nixos.org/options?query={searchTerms}";
                }];
                icon = "file://${../../data/nix-options.png}";
                definedAliases = [ "@no" ];
              };
              "NixOS Wiki" = {
                urls = [{
                  template = "https://wiki.nixos.org/w/index.php?search={searchTerms}";
                }];
                icon = "file://${../../data/nix-wiki.png}";
                definedAliases = [ "@nw" ];
              };
              "bing".metaData.hidden = true;
              "amazon.nl".metaData.hidden = true;
              "google".metaData.hidden = true;
            };
            order = [ "Kagi" "Noogle" "Nix Packages" "Nix Options" "NixOS Wiki" "StartPage" ];
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
  };
}
