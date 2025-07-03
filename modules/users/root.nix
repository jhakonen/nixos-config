{ self, ... }:
{
  flake.modules.homeManager.root = {
    imports = [
      self.modules.homeManager.common
    ];
  };
}
