{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nur.url = "github:nix-community/NUR";
    nur.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager-unstable.url = "github:nix-community/home-manager/master";
    home-manager-unstable.inputs.nixpkgs.follows = "nixpkgs-unstable";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    agenix.inputs.home-manager.follows = "home-manager";
    blueprint.url = "github:numtide/blueprint";
    blueprint.inputs.nixpkgs.follows = "nixpkgs";
    private = {
      url = "git+ssh://github.com:/jhakonen/nixos-config-private.git";
      # url = "path:///home/jhakonen/nixos-config/private";
    };
  };

  outputs = { self
            , agenix
            #, home-manager
            #, home-manager-unstable
            , nixos-hardware
            , nixpkgs
            , nixpkgs-unstable
            , nur
            , private
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
        inherit agenix nur private;
        catalog = pkgs.callPackage ./catalog.nix inputs;
        koti = (pkgs.callPackage ./tools/koti {}).package;
        my-packages = pkgs.callPackage ./packages/nix {};
      };
    };
  in 
    inputs.blueprint {
      inherit inputs;
    };

  /* {
    overlays = {
      unstable-packages = final: prev: {
        unstable = import inputs.nixpkgs-unstable {
          config.allowUnfree = true;
          system = final.system;
        };
      };
    };

    nixosConfigurations.dellxps13 = nixpkgs.lib.nixosSystem {
      modules = [
        ./hosts/dellxps13/configuration.nix
        depInject
        agenix.nixosModules.default
        home-manager.nixosModules.home-manager
        nixos-hardware.nixosModules.common-cpu-intel
        nixos-hardware.nixosModules.common-pc-laptop
        nixos-hardware.nixosModules.common-pc-ssd
        nur.modules.nixos.default
        {
          nixpkgs.overlays = [
            outputs.overlays.unstable-packages
          ];
        }
      ];
    };
*/
    # nixosConfigurations.kanto = nixpkgs.lib.nixosSystem {
    #   modules = [
    #     ./hosts/kanto/configuration.nix
    #     depInject
    #     agenix.nixosModules.default
    #     home-manager.nixosModules.default
    #   ];
    # };

    # nixosConfigurations.mervi = nixpkgs.lib.nixosSystem {
    #   modules = [
    #     ./hosts/mervi/configuration.nix
    #     depInject
    #     agenix.nixosModules.default
    #     home-manager.nixosModules.default
    #     nur.modules.nixos.default
    #   ];
    # };

    # nixosConfigurations.nassuvm = nixpkgs.lib.nixosSystem {
    #   modules = [
    #     ./hosts/nassuvm/configuration.nix
    #     depInject
    #     agenix.nixosModules.default
    #     home-manager.nixosModules.default
    #   ];
    # };

    # nixosConfigurations.toukka = nixpkgs.lib.nixosSystem {
    #   modules = [
    #     ./hosts/toukka/configuration.nix
    #     depInject
    #     agenix.nixosModules.default
    #     home-manager.nixosModules.default
    #   ];
    # };
#  };
}
