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
  in {
    environment.systemPackages = [
      lemonadeBin
      pkgs.unstable.lmstudio
    ];

    # Needed for rocm support, but Lemonade doesn't seem to see it
    hardware.amdgpu.opencl.enable = true;

    networking.firewall.allowedTCPPorts = [
      1234 # LM Studio API
      config.catalog.services.lemonade.port
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
  };
}
