{ inputs, ... }:
{
  catalog = inputs.nixpkgs.lib.recursiveUpdate
    (import ./catalog.nix inputs)
    (import ../encrypted/private-catalog.nix {});
}
