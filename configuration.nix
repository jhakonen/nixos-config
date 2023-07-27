# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, agenix, home-manager, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./modules
      home-manager.nixosModules.default
    ];

  # Bootloader.
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
    useOSProber = true;
  };

  networking.hostName = "nas-toolbox";

  # Enable networking
  networking.networkmanager.enable = true;

  # Salli docker-konteista pääsy isäntäkoneelle
  # networking.firewall.trustedInterfaces = [ "docker0" ];
  # virtualisation.docker.enable = true;
  # virtualisation.oci-containers.backend = "docker";

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
    extraGroups = [
      # "docker"
      "networkmanager"
      "wheel"
    ];
    packages = with pkgs; [];
  };
  home-manager.users = {
    root = {
      home.stateVersion = "23.05";
      programs.ssh.enable = true;
    };
    jhakonen = {
      home.stateVersion = "23.05";
      programs = {
        bash = {
          enable = true;
          profileExtra = ''
            if [ "$XDG_SESSION_TYPE" = "tty" ]; then
              neofetch
            fi
          '';
        };
        git = {
          enable = true;
          userName = "Janne Hakonen";
          userEmail = "***REMOVED***";
          aliases.l = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
        };
        ssh = {
          enable = true;
          matchBlocks."github.com" = {
            identityFile = config.age.secrets.github-id-rsa.path;
            user = "git";
          };
        };
      };
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # Nixpkgs
    git
    inetutils  # telnet
    neofetch

    # Flaket
    agenix.packages."x86_64-linux".default
  ];

  # Estä `inetutils` pakettia korvaamasta `nettools`
  # paketin ohjelmia `ifconfig`, `hostname` ja `dnsdomainname`
  nixpkgs.config.packageOverrides = pkgs: {
    nettools = pkgs.hiPrio pkgs.nettools;
  };

  # Asenna root ca certifikaatti, tarvitaan kun otetaan
  # yhteyttä *.jhakonen.com domaineihin SSL:n yli, esim. MQTT
  security.pki.certificateFiles = [ ./data/root-ca.pem ];

  # Julkinen sertifikaatti *.jhakonen.com domainille
  environment.etc."wildcard-jhakonen-com.cert".text = ''
    -----BEGIN CERTIFICATE-----
    MIIDyzCCArOgAwIBAgIUBJnGD7RBthXhjJ93Jsxc6nNvaSwwDQYJKoZIhvcNAQEL
    BQAwbjELMAkGA1UEBhMCRkkxEDAOBgNVBAcMB1RhbXBlcmUxEDAOBgNVBAoMB0tv
    dGkgT3kxFjAUBgNVBAMMDUphbm5lIEhha29uZW4xIzAhBgkqhkiG9w0BCQEWFGph
    bm5lLmhha29uZW5AaWtpLmZpMB4XDTIyMTIzMDIwMDQyN1oXDTMyMTIyNzIwMDQy
    N1owSjELMAkGA1UEBhMCRkkxEDAOBgNVBAcMB1RhbXBlcmUxEDAOBgNVBAoMB0tv
    dGkgT3kxFzAVBgNVBAMMDiouamhha29uZW4uY29tMIIBIjANBgkqhkiG9w0BAQEF
    AAOCAQ8AMIIBCgKCAQEAk6UB10hQFJP92y+y/EH8T/eG+sEBhyqX8CJzZD3E+2XZ
    kFIHa9AwiA3o9+6Q4sO6aD7qBSV4DmuYoesGqhOf6KakRT2RMea1bZU9GfBfyoG/
    g69MotEid+fLx9Z8o/AjbctAaLDW7O/86kCbJQzLM1Q/NFcMwZh8cirzIT2Lg++x
    9w9NWB3Nha8Xv67+baBD6Jn1ASSEbLAE1oh3GdLbkOSzWBp6if9RzNtgxAxs2+Nq
    YzJo/eGYNuLNhsmjS6dJmvGTLYsie7RTLp1z4pi1umjy6BMNz4k46fe0bclEyPAL
    iwZVtdL2Nc+Dc1KjCiBBUsse0CUzwkKjGrWqUx0Y0wIDAQABo4GEMIGBMB8GA1Ud
    IwQYMBaAFLWuzAgIaGkpO/zkK+YaV3dqHIXpMAkGA1UdEwQCMAAwCwYDVR0PBAQD
    AgTwMCcGA1UdEQQgMB6CDGpoYWtvbmVuLmNvbYIOKi5qaGFrb25lbi5jb20wHQYD
    VR0OBBYEFAi7ZTfX+EGe/78GSSVXtcrA+OR5MA0GCSqGSIb3DQEBCwUAA4IBAQBm
    lf8fCHdCZ+xH/F1eBzBi7ddetGEPJiA8evuSiTVm+0SsR0s0Ivg59NxNrqpSBElz
    YFpg9fewl+5yeCwT7+yN27nmI1pIQh43R5B7GPTzLMqtgymfqFdszUvN80/lWZqA
    tuhaeNROGwpsEek+q1d0Qz61yfH7BWtyM65rT0JOEsLw6DjhDdRU1eDEQHCZd2Vi
    XE+RVRsp2Q8qIzIF99dDMfsAN6NiP1n9UZRvbOjhCacSDw5N739VaggndURnJ8O9
    CRyGcdZbYaPUx24JVxPI+ldY8sq7B0cHWObdTIlM2FXlkudAa0kEIIslKS7twG7D
    0L00UiilmmH5nKd45+5R
    -----END CERTIFICATE-----
  '';

  # Salaisuudet
  age.secrets = {
    borgbackup-id-rsa.file = ./secrets/borgbackup-id-rsa.age;
    borgbackup-password.file = ./secrets/borgbackup-password.age;
    environment-variables.file = ./secrets/environment-variables.age;
    github-id-rsa = {
      file = ./secrets/github-id-rsa.age;
      owner = "jhakonen";
    };
    mosquitto-password = {
      file = ./secrets/mqtt-password.age;
      owner = "mosquitto";
      group = "mosquitto";
    };
    mosquitto-key-file = {
      file = ./secrets/wildcard-jhakonen-com.key.age;
      owner = "mosquitto";
      group = "mosquitto";
    };
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:
  services = {
    # Enable the OpenSSH daemon.
    openssh = {
      enable = true;
      settings = {
        # Vaadi SSH sisäänkirjautuminen käyttäen vain yksityistä avainta
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };

    # Ota häntäverkko käyttöön, vaatii lisäksi komennon suorittamisen:
    #   sudo tailscale up
    tailscale.enable = true;

    # Configure keymap in X11
    xserver = {
      layout = "fi";
      xkbVariant = "nodeadkeys";
    };
  };


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

  apps = {
    backup = {
      enable = true;
      repo = {
        host = "nas";
        user = "borg-backup";
        path = "/volume2/backups/borg/nas-toolbox-nixos";
      };
      paths = [
        "/etc/nixos"
        "/home/jhakonen"
      ];
      excludes = [
        "**/.cache"
        "**/.Trash*"
      ];
      identityFile = config.age.secrets.borgbackup-id-rsa.path;
      passwordFile = config.age.secrets.borgbackup-password.path;
      mounts = {
        "/mnt/borg/kotiautomaatio".remote = "borg-backup@nas:/volume2/backups/borg/nas-kotiautomaatio";
        "/mnt/borg/toolbox".remote        = "borg-backup@nas:/volume2/backups/borg/nas-toolbox-nixos";
        "/mnt/borg/vaultwarden".remote    = "borg-backup@nas:/volume2/backups/borg/vaultwarden";
      };
    };
    grafana.enable = true;
    home-assistant.enable = true;
    influxdb.enable = true;
    mosquitto = {
      enable = true;
      passwordFile = config.age.secrets.mosquitto-password.path;
      certficateFile = "/etc/wildcard-jhakonen-com.cert";
      keyFile = config.age.secrets.mosquitto-key-file.path;
    };
    mqttwarn = {
      enable = true;
      environmentFiles = [ config.age.secrets.environment-variables.path ];
    };
    nitter.enable = true;
    node-red = {
      enable = true;
      environmentFiles = [ config.age.secrets.environment-variables.path ];
    };
    telegraf = {
      enable = true;
      environmentFiles = [ config.age.secrets.environment-variables.path ];
    };
  };
}
