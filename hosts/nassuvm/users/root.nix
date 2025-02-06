{ flake, ... }:
{
  imports = [
    flake.modules.home.zsh
  ];

  home.stateVersion = "24.05";
}
