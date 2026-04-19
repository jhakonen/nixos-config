# Dokumentaatio: obsidian://open?vault=Muistiinpanot&file=Yksityinen%2F0.%20Inbox%2FLocal%20AI
{ inputs, ... }:
{
  den.aspects.dellxps13.nixos = { pkgs, ... }: {
    environment.systemPackages = [
      pkgs.cherry-studio
      pkgs.lmstudio
      pkgs.unstable.mistral-vibe
      pkgs.unstable.opencode
      pkgs.unstable.opencode-desktop
    ];
  };

  den.aspects.mervi.nixos = { config, lib, pkgs, ... }: let
    lemonadeBin = pkgs.writeShellScriptBin "lemonade" ''
      ${lib.getExe pkgs.podman} exec lemonade-server /opt/lemonade/lemonade "$@"
    '';
    models-dir = "/data/ai-models";
    llama-cache-dir = "${models-dir}/llama/cache";
  in {
    environment.variables = {
      # Aseta hakemisto johon llama-cli lataa LLM mallit
      LLAMA_CACHE = llama-cache-dir;
    };

    environment.systemPackages = [
      lemonadeBin
      pkgs.unstable.llama-cpp-vulkan
      pkgs.unstable.lmstudio
    ];

    # Needed for rocm support, but Lemonade doesn't seem to see it
    hardware.amdgpu.opencl.enable = true;

    networking.firewall.allowedTCPPorts = [
      1234 # LM Studio API
      config.catalog.services.lemonade.port
    ];

    # Varmista että llama-swap pystyy lukemaan ladatut tekoälymallit
    systemd.tmpfiles.rules = [
      "d ${models-dir} 0777 root root"
      "Z ${models-dir} 0777 root root"
    ];

    virtualisation.oci-containers.containers.lemonade-server =  let
      imageSource = inputs.lemonade-server { inherit pkgs; };
      inherit (imageSource) image_name image_digest;
    in {
      image = "${image_name}@${image_digest}";
      environment = {
        LEMONADE_LLAMACPP_BACKEND = "vulkan";
      };
      volumes = [
        "/var/lib/lemonade-server/cache:/root/.cache/huggingface:rw"
        "/var/lib/lemonade-server/llama:/opt/lemonade/llama:rw"
      ];
      ports = [
        "${toString config.catalog.services.lemonade.port}:13305"
      ];
    };

    services.llama-swap = let
      setToArgs = set: lib.concatStringsSep " " (
        lib.mapAttrsToList (key: value: "--${key} ${toString value}") set
      );
      defineModel = args: {
        cmd = lib.concatStringsSep " " [
          # Estä koneen suspend/hibernate jos tekoälymalli on ladattuna. Unitila
          # ei näytä toimivan jos tekoälymalli on ladattuna, kone vain herää
          # välittömästi unitilaan menon jälkeen.
          "${pkgs.systemd}/bin/systemd-inhibit --what sleep --who 'llama-swap' --why 'Tekoälymalli ladattu'"
          # Käynnistä itse tekoälymallin palvelu
          "${pkgs.unstable.llama-cpp-vulkan}/bin/llama-server"
          (setToArgs ({ port = "\${PORT}"; } // args))
        ];
      };
    in {
      enable = true;
      package = pkgs.unstable.llama-swap;
      port = config.catalog.services.llama-swap.port;
      openFirewall = true;
      # https://github.com/mostlygeek/llama-swap/blob/main/config.example.yaml
      settings = {
        globalTTL = 3600;
        logToStdout = "both";
        models = {
          # Ladattu komennolla: llama-cli -hf unsloth/Qwen3.6-35B-A3B-GGUF:UD-IQ4_XS
          "qwen3.6-code" = defineModel {
            hf-repo = "unsloth/Qwen3.6-35B-A3B-GGUF:UD-IQ4_XS";
            temp = 0.6;
            top-p = 0.95;
            top-k = 20;
            min-p = 0.00;
            ctx-size = 32768;
          };
          "qwen3.6-general" = defineModel {
            hf-repo = "unsloth/Qwen3.6-35B-A3B-GGUF:UD-IQ4_XS";
            temp = 0.7;
            top-p = 0.8;
            top-k = 20;
            min-p = 0.00;
            reasoning = "off";
            ctx-size = 32768;
          };
        };
      };
    };

    # Määritä staattinen käyttäjä palvelulle
    users.users.llama-swap = {
      isSystemUser = true;
      group = "llama-swap";
    };
    users.groups.llama-swap = {};

    systemd.services.llama-swap = {
      # Määritä ja anna pääsy tekoälymallien hakemistoon
      environment.LLAMA_CACHE = llama-cache-dir;
      serviceConfig.ReadWritePaths = [ llama-cache-dir ];

      # Käytä staattista käyttäjää jotta systemd-inhibit toimii
      serviceConfig.User = "llama-swap";
      serviceConfig.DynamicUser = lib.mkForce false;

      # Korjaa virhe lokissa: Failed to create //.cache for shader cache
      # https://github.com/NixOS/nixpkgs/issues/441531#issuecomment-3283517940
      environment.XDG_CACHE_HOME = "/var/cache/llama-swap";
      serviceConfig.CacheDirectory = "llama-swap";
    };

    # Anna llama-swap käyttäjälle oikeus ajaa "systemd-inhibit --what sleep ..." komento
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.login1.inhibit-block-sleep" &&
          subject.user == "llama-swap") {
          return polkit.Result.YES;
        }
      });
    '';
  };

  den.aspects.kanto.nixos = { config, pkgs, ... }: {
    environment.systemPackages = [
      pkgs.unstable.llama-swap.wol
    ];

    # Tämä palvelu herättää Mervin automaattisesti WOL viestillä jos kone ei
    # ole käynnissä kun llama-swap palvelua tai tekoälymallia yritetään käyttää
    systemd.services.llama-swap-wol-proxy = {
      description = "WOL proxy for llama-swap on mervi";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      script = ''
        ${pkgs.unstable.llama-swap.wol}/bin/wol-proxy \
          -listen 127.0.0.1:${toString config.catalog.services.llama-swap.port} \
          -upstream http://mervi:${toString config.catalog.services.llama-swap.port} \
          -mac A8:A1:59:52:68:A4
      '';
    };

    # Paljasta llama-swap ja tekoälymallien API osoitteessa:
    #   http://llama-swap.kanto.lan.jhakonen.com/
    services.nginx.virtualHosts.${config.catalog.services.llama-swap.public.domain}.locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.catalog.services.llama-swap.port}";
      recommendedProxySettings = true;
      # Anna Merville aikaa käynnistyä (WOL) ja mallille aikaa latautua
      extraConfig = ''
        proxy_connect_timeout   120s;
        proxy_send_timeout      120s;
        proxy_read_timeout      120s;
      '';
    };
  };
}
