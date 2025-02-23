{ flake, ... }:
{
  imports = [
    flake.modules.home.common
  ];

  home.stateVersion = "24.05";
}
