let

  outputs =
    inputs:
    (inputs.nixpkgs-unstable.lib.evalModules {
      modules = [ (inputs.import-tree ./modules) ];
      specialArgs = {
        inherit (inputs) self;
        inputs = inputs // {
          nixpkgs = inputs.nixpkgs-unstable;
          home-manager = inputs.home-manager-unstable;
        };
      };
    }).config;

in
import ./with-inputs.nix outputs
