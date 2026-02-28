{ inputs, ... }:
{
  den.aspects.dellxps13.nixos = { pkgs, ... }: {
    imports = [
      inputs.nix-flatpak.nixosModules.nix-flatpak
    ];

    services.flatpak = {
      enable = true;
      update.auto.enable = true;
    };

    system.activationScripts = {
      # https://github.com/gmodena/nix-flatpak/issues/175
      updateDesktopDatabase = {
        text = "${pkgs.desktop-file-utils}/bin/update-desktop-database /var/lib/flatpak/exports/share/applications";
      };
    };
  };
}
