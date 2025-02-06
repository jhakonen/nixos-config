{ flake, ... }:
{
  imports = [
    flake.modules.home.zsh
  ];

  home.stateVersion = "23.05";
  home.enableNixpkgsReleaseCheck = false;
}
