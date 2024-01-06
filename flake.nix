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

  outputs = { self, nixos-hardware, nixpkgs, nixpkgs-unstable, agenix, home-manager, ... }@inputs: let
    inherit (self) outputs;
    catalog = import ./catalog.nix inputs;
  in {
    overlays = {
      unstable-packages = final: prev: {
        unstable = import inputs.nixpkgs-unstable { system = final.system; };
      };
    };

    nixosConfigurations.dellxps13 = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      specialArgs = { inherit catalog; } // inputs;
      modules = [
        ./hosts/dellxps13/configuration.nix
        ({ ... }: {
          nixpkgs.overlays = [
            (final: prev: {
              unstable = import nixpkgs-unstable {
                inherit system;
                config.allowUnfree = true;
              };
            })
          ];
        })
        agenix.nixosModules.default
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            extraSpecialArgs = {
              inherit outputs;
              inherit catalog;
              inherit agenix;
            };
            users.jhakonen = import ./hosts/dellxps13/home.nix;
          };
          # home-manager.useGlobalPkgs = true;
          # home-manager.useUserPackages = true;

          # Optionally, use home-manager.extraSpecialArgs to pass
          # arguments to home.nix
        }
        nixos-hardware.nixosModules.common-cpu-intel
        nixos-hardware.nixosModules.common-pc-laptop
        nixos-hardware.nixosModules.common-pc-ssd
      ];
    };

    nixosConfigurations.nas-toolbox = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit catalog; } // inputs;
      modules = [
        ./hosts/nas-toolbox/configuration.nix
        agenix.nixosModules.default
      ];
    };

    nixosConfigurations.mervi = nixpkgs-unstable.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit catalog;
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
        inherit catalog;
        my-packages = import ./packages/nix {
          pkgs = nixpkgs.legacyPackages.aarch64-linux;
        };
      } // inputs;
      modules = [
        ./hosts/kota-portti/configuration.nix
        agenix.nixosModules.default
      ];
    };
  };
}
