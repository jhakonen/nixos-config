{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nur.url = "github:nix-community/NUR";
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager-unstable.url = "github:nix-community/home-manager";
    home-manager-unstable.inputs.nixpkgs.follows = "nixpkgs-unstable";
    lollypops.url = "github:pinpox/lollypops";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    agenix.inputs.home-manager.follows = "home-manager";
  };

  outputs = { self
            , agenix
            , home-manager
            , home-manager-unstable
            , lollypops
            , nixos-hardware
            , nixpkgs
            , nixpkgs-unstable
            , nur
            , ... }@inputs:
  let
    inherit (self) outputs;
    depInject = { lib, pkgs, ... }: {
      options.dep-inject = lib.mkOption {
        type = with lib.types; attrsOf unspecified;
        default = {};
      };
      config.dep-inject = {
        # Injektoi riippuvuudet `specialArgs` muuttujan sijaan, lähde:
        #   https://jade.fyi/blog/flakes-arent-real/#injecting-dependencies
        inherit agenix;
        catalog = pkgs.callPackage ./catalog.nix inputs;
        my-packages = pkgs.callPackage ./packages/nix {};
      };
    };
    lollypops-reboot-task = { config, ... }: {
      lollypops.extraTasks.reboot = {
        desc = "Reboot machine";
        cmds = [
          "echo Rebooting machine"
          "ssh ${config.lollypops.deployment.ssh.user}@${config.lollypops.deployment.ssh.host} reboot"
        ];
      };
    };
    lollypops-rebuild-debug-task = { config, ... }: {
      lollypops.extraTasks.rebuild-debug = {
        desc = "Rebuild with debug output";
        cmds = [
          "echo Rebuilding with debug information"
          ''
          ssh ${config.lollypops.deployment.ssh.user}@${config.lollypops.deployment.ssh.host} \
            nixos-rebuild switch \
              --flake '${config.lollypops.deployment.config-dir}#${config.lollypops.deployment.ssh.host}' \
              --show-trace --verbose --option eval-cache false
          ''
        ];
      };
    };
  in {
    overlays = {
      unstable-packages = final: prev: {
        unstable = import inputs.nixpkgs-unstable {
          config.allowUnfree = true;
          system = final.system;
        };
      };
    };

    nixosConfigurations.dellxps13 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts/dellxps13/configuration.nix
        depInject
        agenix.nixosModules.default
        home-manager.nixosModules.home-manager
        lollypops.nixosModules.lollypops
        lollypops-rebuild-debug-task
        nixos-hardware.nixosModules.common-cpu-intel
        nixos-hardware.nixosModules.common-pc-laptop
        nixos-hardware.nixosModules.common-pc-ssd
        nur.nixosModules.nur
        {
          nixpkgs.overlays = [
            outputs.overlays.unstable-packages
          ];
          lollypops.deployment.ssh.host = "localhost";
        }
      ];
    };

    nixosConfigurations.nas-toolbox = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts/nas-toolbox/configuration.nix
        depInject
        agenix.nixosModules.default
        home-manager.nixosModules.default
        lollypops.nixosModules.lollypops
        lollypops-reboot-task
        lollypops-rebuild-debug-task
      ];
    };

    nixosConfigurations.mervi = nixpkgs-unstable.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts/mervi/configuration.nix
        depInject
        agenix.nixosModules.default
        home-manager-unstable.nixosModules.default
        lollypops.nixosModules.lollypops
        nur.nixosModules.nur
        lollypops-reboot-task
        lollypops-rebuild-debug-task
      ];
    };

    nixosConfigurations.kota-portti = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        ./hosts/kota-portti/configuration.nix
        depInject
        agenix.nixosModules.default
        home-manager.nixosModules.default
        lollypops.nixosModules.lollypops
        lollypops-reboot-task
        lollypops-rebuild-debug-task
      ];
    };

    apps."x86_64-linux".default = lollypops.apps."x86_64-linux".default { configFlake = self; };
  };
}
