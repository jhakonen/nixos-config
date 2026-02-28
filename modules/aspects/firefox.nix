{ ... }:
{
  # Perustuu ohjeisiin:
  #   https://discourse.nixos.org/t/nixos-firefox-configuration-with-policies-preferences-extensions-search-engines-and-cookie-exceptions/73747
  den.aspects.dellxps13.nixos = { config, pkgs, ... }: let
    # about:support#addons-tbody
    extensions = [
      "gdpr@cavi.au.dk"                  # Consent-O-Matic
      "@testpilot-containers"            # Firefox Multi-Account Containers
      "search@kagi.com"                  # Kagi Search for Firefox
      "addon@karakeep.app"               # Karakeep
      "keepassxc-browser@keepassxc.org"  # KeePassXC-Browser
    ];
    rootDir = "/var/lib/www";
  in {
    programs.firefox = {
      enable = true;
      languagePacks = [ "fi" "en-US" ];
      # https://mozilla.github.io/policy-templates/
      policies = {
        DisableFirefoxStudies = true;
        SearchEngines = {
          Remove = [
              "eBay"
              "Google"
              "Bing"
              "Ecosia"
              "Wikipedia"
              "Perplexity"
          ];
          Add = [
            {
              "Name" = "Kagi";
              "URLTemplate" = "https://kagi.com/search?q={searchTerms}";
              "IconURL" = "https://kagi.com/favicon.ico";
              "Alias" = "k";
            }
            {
              "Name" = "StartPage";
              "URLTemplate" = "https://www.startpage.com/sp/search?query={searchTerms}";
              "IconURL" = "https://www.startpage.com/favicon.ico";
              "Alias" = "sp";
            }
            {
              "Name" = "Noogle";
              "URLTemplate" = "https://noogle.dev?term={searchTerms}";
              "IconURL" = "http://localhost:8787/noogle.png";
              "Alias" = "nog";
            }
            {
              "Name" = "Nix Packages";
              "URLTemplate" = "https://search.nixos.org/packages?query={searchTerms}";
              "IconURL" = "http://localhost:8787/nix-packages.png";
              "Alias" = "np";
            }
            {
              "Name" = "Nix Options";
              "URLTemplate" = "https://search.nixos.org/options?query={searchTerms}";
              "IconURL" = "http://localhost:8787/nix-options.png";
              "Alias" = "no";
            }
            {
              "Name" = "NixOS Wiki";
              "URLTemplate" = "https://wiki.nixos.org/w/index.php?search={searchTerms}";
              "IconURL" = "http://localhost:8787/nix-wiki.png";
              "Alias" = "nw";
            }
          ];
          Default = "Kagi";
        };
        ExtensionSettings = builtins.listToAttrs (builtins.map (id: {
          name = id;
          value = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/${id}/latest.xpi";
            installation_mode = "force_installed";
          };
        }) extensions);
      };

      # Miten tiedän mitä asetuksia muuttaa:
      # 1. Tee varmuuskopio prefs.js tiedostosta:  $ cp ~/.mozilla/firefox/hakonen/{prefs.js,prefs.js.bak}
      # 2. Tee muutos Firefoxin asetuksiin selaimen käyttöliittymän kautta
      # 3. Vertaa prefs.js tiedostoa ja sen varmuuskopioita:  $ meld ~/.mozilla/firefox/hakonen/{prefs.js.bak,prefs.js}
      preferences = {
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
    # Firefox ei lataa hakukoneiden ikoneita file:-protokollalla joten tarjoile Nix-ikonit
    # HTTP-palvelimen kautta. Palvelin on osoitteessa http://localhost:8787/.
    services.static-web-server = {
      enable = true;
      root = rootDir;
    };
    systemd.tmpfiles.rules = [
      "d ${rootDir} 0755"
      "C ${rootDir}/noogle.png - - - - ${../../data/noogle.png}"
      "C ${rootDir}/nix-packages.png - - - - ${../../data/nix-packages.png}"
      "C ${rootDir}/nix-options.png - - - - ${../../data/nix-options.png}"
      "C ${rootDir}/nix-wiki.png - - - - ${../../data/nix-wiki.png}"
    ];
  };
}
