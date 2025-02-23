{ flake, ... }:
{
  imports = [
    flake.modules.home.common
  ];

  home.stateVersion = "23.05";
  home.enableNixpkgsReleaseCheck = false;
}
