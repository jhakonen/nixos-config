{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    home-manager.url = "github:nix-community/home-manager/release-23.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    agenix.inputs.home-manager.follows = "home-manager";
  };

  outputs = { self, nixpkgs, agenix, home-manager, ... }@attrs: {

    nixosConfigurations.nas-toolbox = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = attrs;
      modules = [
        ./hosts/nas-toolbox/configuration.nix
        agenix.nixosModules.default
      ];
    };

    homeConfigurations."jhakonen@dellxps13" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      extraSpecialArgs = attrs;
      modules = [
        ./hosts/dellxps13/home.nix
        agenix.homeManagerModules.age
      ];
    };

  };
}
