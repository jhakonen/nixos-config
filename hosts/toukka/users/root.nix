{ flake, ... }:
{
  imports = [
    flake.modules.home.common
  ];

  home.stateVersion = "23.11";
}
