{ pkgs, ... }:
{
  fonts.fontconfig.enable = true;
  home.packages = [
    pkgs.fira-code
    pkgs.fira-code-symbols
    pkgs.font-awesome
    pkgs.liberation_ttf
    pkgs.mplus-outline-fonts.githubRelease
    pkgs.nerdfonts
    pkgs.noto-fonts
    pkgs.noto-fonts-emoji
    pkgs.proggyfonts
  ];
}
