{ inputs, self, ... }:
{
  flake.modules.nixos.tunneli = { config, lib, pkgs, ... }: let
    inherit (self) catalog;
  in {
    boot.loader.grub.enable = true;
    boot.loader.grub.device = "/dev/sda";

    imports = [
      inputs.agenix.nixosModules.default
      inputs.home-manager.nixosModules.home-manager
      self.modules.nixos.common
      self.modules.nixos.kotisivu
      self.modules.nixos.n8n-tunnel
      self.modules.nixos.nextcloud-tunnel
      self.modules.nixos.nginx
      self.modules.nixos.tailscale
    ];

    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    # Ota Let's Encryptin sertifikaatti käyttöön
    security.acme.certs."jhakonen.com".extraDomainNames = [
      "*.jhakonen.com"
      "*.tunneli.public.jhakonen.com"
    ];

    services.openssh.enable = true;

    # Älä muuta ellei ole pakko, ei edes uudempaan versioon päivittäessä
    system.stateVersion = "25.05";

    users.users.jhakonen = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
    };
  };

  flake.modules.homeManager.tunneli = {
    home.stateVersion = "25.05";
  };
}
