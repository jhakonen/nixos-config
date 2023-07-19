{
  inputs.agenix.url = "github:ryantm/agenix";
  inputs.home-manager.url = github:nix-community/home-manager;

  outputs = { self, nixpkgs, agenix, ... }@attrs: {
    nixosConfigurations.nas-toolbox = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = attrs;
      modules = [
        ./configuration.nix
        agenix.nixosModules.default
      ];
    };
  };
}
