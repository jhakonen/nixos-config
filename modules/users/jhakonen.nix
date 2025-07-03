{ self, ... }:
{
  flake.modules.homeManager.jhakonen = {
    imports = [
      self.modules.homeManager.common
      self.modules.homeManager.mqtt-client
    ];
  };
}
