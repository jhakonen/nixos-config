# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./docker-nitter.nix
    ];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "nas-toolbox"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Helsinki";

  # Select internationalisation properties.
  i18n.defaultLocale = "fi_FI.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "fi_FI.UTF-8";
    LC_IDENTIFICATION = "fi_FI.UTF-8";
    LC_MEASUREMENT = "fi_FI.UTF-8";
    LC_MONETARY = "fi_FI.UTF-8";
    LC_NAME = "fi_FI.UTF-8";
    LC_NUMERIC = "fi_FI.UTF-8";
    LC_PAPER = "fi_FI.UTF-8";
    LC_TELEPHONE = "fi_FI.UTF-8";
    LC_TIME = "fi_FI.UTF-8";
  };

  # Configure keymap in X11
  services.xserver = {
    layout = "fi";
    xkbVariant = "nodeadkeys";
  };

  # Configure console keymap
  console.keyMap = "fi";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.jhakonen = {
    # Julkinen avain SSH:lla sisäänkirjautumista varten
    openssh.authorizedKeys.keys = [(
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDMqorF45N0aG+QqJbRt7kRcmXXbsgvXw7"
      + "+cfWuVt6JKLLLo8Tr7YY/HQfAI3+u1TPo+h7NMLfr6E1V3kAHt7M5K+fZ+XYqBvfHT7F8"
      + "jlEsq6azIoLWujiveb7bswvkTdeO/fsg+QZEep32Yx2Na5//9cxdkYYwmmW0+TXemilZH"
      + "l+mVZ8PeZPj+FQhBMsBM+VGJXCZaW+YWEg8/mqGT0p62U9UkolNFfppS3gKGhkiuly/kS"
      + "KjVgSuuKy6h0M5WINWNXKh9gNz9sNnzrVi7jx1RXaJ48sx4BAMJi1AqY3Nu50z4e/wUoi"
      + "AN7fYDxM/AHxtRYg4tBWjuNCaVGB/413h46Alz1Y7C43PbIWbSPAmjw1VDG+i1fOhsXnx"
      + "cLJQqZUd4Jmmc22NorozaqwZkzRoyf+i604QPuFKMu5LDTSfrDfMvkQFY9E1zZgf1LAZT"
      + "LePrfld8YYg/e/+EO0iIAO7dNrxg6Hi7c2zN14cYs+Z327T+/Iqe4Dp1KVK1KQLqJF0Hf"
      + "907fd+UIXhVsd/5ZpVl3G398tYbLk/fnJum4nWUMhNiDQsoEJyZs1QoQFDFD/o1qxXCOo"
      + "Cq0tb5pheaYWRd1iGOY0x2dI6TC2nl6ZVBB6ABzHoRLhG+FDnTWvPTodY1C7rTzUVyWOn"
      + "QZdUqOqF3C79F3f/MCrYk3/CvtbDtQ== jhakonen"
    )];
    isNormalUser = true;
    description = "Janne Hakonen";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget
    inetutils
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      # Vaadi SSH sisäänkirjautuminen käyttäen vain yksityistä avainta
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # Ota häntäverkko käyttöön, vaatii lisäksi komennon suorittamisen:
  #   sudo tailscale up
  services.tailscale.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

  virtualisation.docker.enable = true;
  virtualisation.oci-containers.backend = "docker";

  # Nitter service
  services.docker-nitter = {
    enable = true;
    server = {
      port = 11000;
      hostname = "nitter.jhakonen.com";
    };
    redisCreateLocally = true;
    openFirewall = true;
  };



  #services.redis.servers.nitter = {
  #  enable = true;
  #  logLevel = "warning";
  #  port = 6379;
  #  save = [[60 1]];
  #};
  #environment.etc."nitter.conf".text = ''
  #  [Server]
  #  address = "0.0.0.0"
  #  port = 8080
  #  https = false  # disable to enable cookies when not using https
  #  httpMaxConnections = 100
  #  staticDir = "./public"
  #  title = "nitter"
  #  hostname = "nitter.jhakonen.com"

  #  [Cache]
  #  listMinutes = 240  # how long to cache list info (not the tweets, so keep it high)
  #  rssMinutes = 10  # how long to cache rss queries
  #  redisHost = "172.17.0.1"  # Change to "nitter-redis" if using docker-compose
  #  redisPort = ${toString config.services.redis.servers.nitter.port}
  #  redisPassword = ""
  #  redisConnections = 20  # connection pool size
  #  redisMaxConnections = 30
  #  # max, new connections are opened when none are available, but if the pool size
  #  # goes above this, they're closed when released. don't worry about this unless
  #  # you receive tons of requests per second

  #  [Config]
  #  hmacKey = "4g2j3hg54j5v4jk3b534kj5h453kjh"  # random key for cryptographic signing of video urls
  #  base64Media = false  # use base64 encoding for proxied media urls
  #  enableRSS = true  # set this to false to disable RSS feeds
  #  enableDebug = false  # enable request logs and debug endpoints
  #  proxy = ""  # http/https url, SOCKS proxies are not supported
  #  proxyAuth = ""
  #  tokenCount = 10
  #  # minimum amount of usable tokens. tokens are used to authorize API requests,
  #  # but they expire after ~1 hour, and have a limit of 187 requests.
  #  # the limit gets reset every 15 minutes, and the pool is filled up so there's
  #  # always at least $tokenCount usable tokens. again, only increase this if
  #  # you receive major bursts all the time

  #  # Change default preferences here, see src/prefs_impl.nim for a complete list
  #  [Preferences]
  #  theme = "Nitter"
  #  replaceTwitter = "nitter.net"
  #  replaceYouTube = "piped.video"
  #  replaceReddit = "teddit.net"
  #  replaceInstagram = ""
  #  proxyVideos = true
  #  hlsPlayback = false
  #  infiniteScroll = false
  #'';
}
