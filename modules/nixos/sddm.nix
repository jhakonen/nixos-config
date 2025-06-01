{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.kdePackages.plasma-desktop ];

  qt.enable = true;

  services.displayManager.sddm = {
    enable = true;
    extraPackages = with pkgs.kdePackages; [
      kirigami
      libplasma
      plasma5support
    ];
    package = pkgs.kdePackages.sddm;
    theme = "breeze";
    wayland.enable = true;
  };
}
