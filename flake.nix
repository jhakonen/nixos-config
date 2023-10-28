{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-23.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    agenix.inputs.home-manager.follows = "home-manager";
  };

  outputs = { self, nixpkgs, agenix, home-manager, unstable, ... }@attrs: {

    nixosConfigurations.nas-toolbox = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { catalog = import ./catalog.nix attrs; } // attrs;
      modules = [
        ./hosts/nas-toolbox/configuration.nix
        agenix.nixosModules.default
      ];
    };

    nixosConfigurations.mervi = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { catalog = import ./catalog.nix attrs; } // attrs;
      modules = [
        ./hosts/mervi/configuration.nix
        agenix.nixosModules.default
      ];
    };

    nixosConfigurations.kota-portti = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      specialArgs = {
        catalog = import ./catalog.nix attrs;
        my-packages = import ./packages/nix {
          pkgs = nixpkgs.legacyPackages.aarch64-linux;
        };
      } // attrs;
      modules = [
        ./hosts/kota-portti/configuration.nix
        agenix.nixosModules.default
      ];
    };

    homeConfigurations."jhakonen@dellxps13" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      extraSpecialArgs = { catalog = import ./catalog.nix attrs; } // attrs;
      modules = [
        ({ ... }: {
          nixpkgs.overlays = [
            (final: prev: {
              unstable = import unstable { system = "x86_64-linux"; };
            })
          ];
        })
        ./hosts/dellxps13/home.nix
        agenix.homeManagerModules.age
      ];
    };

  };
}
