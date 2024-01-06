{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager-unstable.url = "github:nix-community/home-manager";
    home-manager-unstable.inputs.nixpkgs.follows = "nixpkgs-unstable";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    agenix.inputs.home-manager.follows = "home-manager";
  };

  outputs = { self, nixos-hardware, nixpkgs, nixpkgs-unstable, agenix, home-manager, home-manager-unstable, ... }@inputs:
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
  in {
    overlays = {
      unstable-packages = final: prev: {
        unstable = import inputs.nixpkgs-unstable {
          config.allowUnfree = true;
          system = final.system;
        };
      };
    };

    nixosConfigurations.dellxps13 = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      modules = [
        depInject
        ./hosts/dellxps13/configuration.nix
        {
          nixpkgs.overlays = [
            outputs.overlays.unstable-packages
          ];
          home-manager.users.jhakonen = import ./hosts/dellxps13/home.nix;
        }
        agenix.nixosModules.default
        home-manager.nixosModules.home-manager
        nixos-hardware.nixosModules.common-cpu-intel
        nixos-hardware.nixosModules.common-pc-laptop
        nixos-hardware.nixosModules.common-pc-ssd
      ];
    };

    nixosConfigurations.nas-toolbox = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        depInject
        ./hosts/nas-toolbox/configuration.nix
        agenix.nixosModules.default
        home-manager.nixosModules.default
      ];
    };

    nixosConfigurations.mervi = nixpkgs-unstable.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        depInject
        ./hosts/mervi/configuration.nix
        agenix.nixosModules.default
        home-manager-unstable.nixosModules.default
      ];
    };

    nixosConfigurations.kota-portti = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        depInject
        ./hosts/kota-portti/configuration.nix
        agenix.nixosModules.default
        home-manager.nixosModules.default
      ];
    };
  };
}
