# Kopioitu osoitteesta https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/misc/nitter.nix
# ja muokattu käyttämään docker-konttia systemd-palvelun sijaan
# Tämä mahdollistaa Nitterin nopeamman päivityksen jos Elon Musk taas rikkoo Twitterin
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.docker-nitter;
  configFile = pkgs.writeText "nitter.conf" ''
    ${generators.toINI {
      # String values need to be quoted
      mkKeyValue = generators.mkKeyValueDefault {
        mkValueString = v:
          if isString v then "\"" + (strings.escape ["\""] (toString v)) + "\""
          else generators.mkValueStringDefault {} v;
      } " = ";
    } (lib.recursiveUpdate {
      Server = cfg.server;
      Cache = cfg.cache;
      Config = cfg.config;
      Preferences = cfg.preferences;
    } cfg.settings)}
  '';
in
{
  options = {
    services.docker-nitter = {
      enable = mkEnableOption (lib.mdDoc "Nitter");

      server = {
        address = mkOption {
          type =  types.str;
          default = "0.0.0.0";
          example = "127.0.0.1";
          description = lib.mdDoc "The address to listen on.";
        };

        port = mkOption {
          type = types.port;
          default = 8080;
          example = 8000;
          description = lib.mdDoc "The port to listen on.";
        };

        https = mkOption {
          type = types.bool;
          default = false;
          description = lib.mdDoc "Set secure attribute on cookies. Keep it disabled to enable cookies when not using HTTPS.";
        };

        httpMaxConnections = mkOption {
          type = types.int;
          default = 100;
          description = lib.mdDoc "Maximum number of HTTP connections.";
        };

        staticDir = mkOption {
          type = types.str;
          default = "./public";
          defaultText = "./public";
          description = lib.mdDoc "Path to the static files directory.";
        };

        title = mkOption {
          type = types.str;
          default = "nitter";
          description = lib.mdDoc "Title of the instance.";
        };

        hostname = mkOption {
          type = types.str;
          default = "localhost";
          example = "nitter.net";
          description = lib.mdDoc "Hostname of the instance.";
        };
      };

      cache = {
        listMinutes = mkOption {
          type = types.int;
          default = 240;
          description = lib.mdDoc "How long to cache list info (not the tweets so keep it high).";
        };

        rssMinutes = mkOption {
          type = types.int;
          default = 10;
          description = lib.mdDoc "How long to cache RSS queries.";
        };

        redisHost = mkOption {
          type = types.str;
          default = "";
          description = lib.mdDoc "Redis host.";
        };

        redisPort = mkOption {
          type = types.port;
          default = 6379;
          description = lib.mdDoc "Redis port.";
        };

        redisPassword = mkOption {
          type = types.str;
          default = "";
          description = lib.mdDoc "Redis password.";
        };

        redisConnections = mkOption {
          type = types.int;
          default = 20;
          description = lib.mdDoc "Redis connection pool size.";
        };

        redisMaxConnections = mkOption {
          type = types.int;
          default = 30;
          description = lib.mdDoc ''
            Maximum number of connections to Redis.

            New connections are opened when none are available, but if the
            pool size goes above this, they are closed when released, do not
            worry about this unless you receive tons of requests per second.
          '';
        };
      };

      config = {
        base64Media = mkOption {
          type = types.bool;
          default = false;
          description = lib.mdDoc "Use base64 encoding for proxied media URLs.";
        };

        enableRSS = mkEnableOption (lib.mdDoc "RSS feeds") // { default = true; };

        enableDebug = mkEnableOption (lib.mdDoc "request logs and debug endpoints");

        hmacKey = mkOption {
          type = types.str;
          default = "";
          description = lib.mdDoc "HMAC key.";
        };

        proxy = mkOption {
          type = types.str;
          default = "";
          description = lib.mdDoc "URL to a HTTP/HTTPS proxy.";
        };

        proxyAuth = mkOption {
          type = types.str;
          default = "";
          description = lib.mdDoc "Credentials for proxy.";
        };

        tokenCount = mkOption {
          type = types.int;
          default = 10;
          description = lib.mdDoc ''
            Minimum amount of usable tokens.

            Tokens are used to authorize API requests, but they expire after
            ~1 hour, and have a limit of 187 requests. The limit gets reset
            every 15 minutes, and the pool is filled up so there is always at
            least tokenCount usable tokens. Only increase this if you receive
            major bursts all the time.
          '';
        };
      };

      preferences = {
        replaceTwitter = mkOption {
          type = types.str;
          default = "";
          example = "nitter.net";
          description = lib.mdDoc "Replace Twitter links to this instance (blank to disable).";
        };

        replaceYouTube = mkOption {
          type = types.str;
          default = "";
          example = "piped.kavin.rocks";
          description = lib.mdDoc "Replace YouTube links to this instance (blank to disable).";
        };

        replaceReddit = mkOption {
          type = types.str;
          default = "";
          example = "teddit.net";
          description = lib.mdDoc "Replace Reddit links to this instance (blank to disable).";
        };

        mp4Playback = mkOption {
          type = types.bool;
          default = true;
          description = lib.mdDoc "Enable MP4 video playback.";
        };

        hlsPlayback = mkOption {
          type = types.bool;
          default = false;
          description = lib.mdDoc "Enable HLS video streaming (requires JavaScript).";
        };

        proxyVideos = mkOption {
          type = types.bool;
          default = true;
          description = lib.mdDoc "Proxy video streaming through the server (might be slow).";
        };

        muteVideos = mkOption {
          type = types.bool;
          default = false;
          description = lib.mdDoc "Mute videos by default.";
        };

        autoplayGifs = mkOption {
          type = types.bool;
          default = true;
          description = lib.mdDoc "Autoplay GIFs.";
        };

        theme = mkOption {
          type = types.str;
          default = "Nitter";
          description = lib.mdDoc "Instance theme.";
        };

        infiniteScroll = mkOption {
          type = types.bool;
          default = false;
          description = lib.mdDoc "Infinite scrolling (requires JavaScript experimental).";
        };

        stickyProfile = mkOption {
          type = types.bool;
          default = true;
          description = lib.mdDoc "Make profile sidebar stick to top.";
        };

        bidiSupport = mkOption {
          type = types.bool;
          default = false;
          description = lib.mdDoc "Support bidirectional text (makes clicking on tweets harder).";
        };

        hideTweetStats = mkOption {
          type = types.bool;
          default = false;
          description = lib.mdDoc "Hide tweet stats (replies retweets likes).";
        };

        hideBanner = mkOption {
          type = types.bool;
          default = false;
          description = lib.mdDoc "Hide profile banner.";
        };

        hidePins = mkOption {
          type = types.bool;
          default = false;
          description = lib.mdDoc "Hide pinned tweets.";
        };

        hideReplies = mkOption {
          type = types.bool;
          default = false;
          description = lib.mdDoc "Hide tweet replies.";
        };

        squareAvatars = mkOption {
          type = types.bool;
          default = false;
          description = lib.mdDoc "Square profile pictures.";
        };
      };

      settings = mkOption {
        type = types.attrs;
        default = {};
        description = lib.mdDoc ''
          Add settings here to override NixOS module generated settings.

          Check the official repository for the available settings:
          https://github.com/zedeus/nitter/blob/master/nitter.example.conf
        '';
      };

      openFirewall = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Open ports the firewall for Nitter web interface.";
      };
    };
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.nitter = {
      image = "zedeus/nitter:latest";
      ports = [ "${toString cfg.server.port}:${toString cfg.server.port}" ];
      volumes = [ "${configFile}:/src/nitter.conf:ro" ];
      extraOptions = [ "--pull=newer" ];
    };

    # Nitter ei osaa ottaa sigterm:ä vastaan, joten tapa se nopeasti
    systemd.services."${config.virtualisation.oci-containers.backend}-nitter".serviceConfig.TimeoutStopSec = lib.mkForce 1;

    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.server.port ];
    };
  };
}
