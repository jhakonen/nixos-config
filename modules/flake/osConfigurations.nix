{ inputs, lib, ... }:
let
  mkHmImports = host: user: {
    home-manager.users.${user}.imports = [
      (inputs.self.modules.homeManager.${user} or {})
      (inputs.self.modules.homeManager.${host} or {})
      (inputs.self.modules.homeManager."${host}-${user}" or {})
    ];
  };

  mkNixos =
    system: name:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        inputs.self.modules.nixos.nixos
        inputs.self.modules.nixos.${name}
        {
          networking.hostName = lib.mkDefault name;
          nixpkgs.hostPlatform = lib.mkDefault system;
          system.stateVersion = lib.mkDefault "25.05";
        }
        (mkHmImports name "jhakonen")
        (mkHmImports name "root")
      ];
    };
  linux = mkNixos "x86_64-linux";
  linux-arm = mkNixos "aarch64-linux";
in
{
  imports = [
    inputs.flake-parts.flakeModules.modules
  ];

  flake.nixosConfigurations = {
    dellxps13 = linux "dellxps13";
    kanto = linux "kanto";
    mervi = linux "mervi";
    nassuvm = linux "nassuvm";
    tunneli = linux "tunneli";
  };

  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
}
