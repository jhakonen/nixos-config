{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager-unstable.url = "github:nix-community/home-manager";
    home-manager-unstable.inputs.nixpkgs.follows = "nixpkgs-unstable";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    agenix.inputs.home-manager.follows = "home-manager";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, agenix, home-manager, ... }@inputs: let
    inherit (self) outputs;
  in {
    overlays = {
      unstable-packages = final: prev: {
        unstable = import inputs.nixpkgs-unstable { system = final.system; };
      };
    };

    nixosConfigurations.nas-toolbox = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { catalog = import ./catalog.nix inputs; } // inputs;
      modules = [
        ./hosts/nas-toolbox/configuration.nix
        agenix.nixosModules.default
      ];
    };

    nixosConfigurations.mervi = nixpkgs-unstable.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        catalog = import ./catalog.nix inputs;
        inherit outputs;
      } // inputs;
      modules = [
        ./hosts/mervi/configuration.nix
        agenix.nixosModules.default
      ];
    };

    nixosConfigurations.kota-portti = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      specialArgs = {
        catalog = import ./catalog.nix inputs;
        my-packages = import ./packages/nix {
          pkgs = nixpkgs.legacyPackages.aarch64-linux;
        };
      } // inputs;
      modules = [
        ./hosts/kota-portti/configuration.nix
        agenix.nixosModules.default
      ];
    };

    homeConfigurations."jhakonen@dellxps13" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      extraSpecialArgs = {
        catalog = import ./catalog.nix inputs;
        inherit outputs;
      } // inputs;
      modules = [
        ./hosts/dellxps13/home.nix
        agenix.homeManagerModules.age
      ];
    };

  };
}
