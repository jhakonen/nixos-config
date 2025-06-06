{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.nemo-with-extensions
  ];
  services.gvfs.enable = true;
}
