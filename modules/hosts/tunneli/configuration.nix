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
      self.modules.nixos.seafile-tunnel
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
    users.users.root = {
      openssh.authorizedKeys.keys = [
        # Tarvitaan jotta seafilen access logit saa välitettyä tunnelikoneen
        # fail2bannille
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFSiO4bqkEy4slae5/oPXW9kMfvE23vOu+hjbaBJZ8rr tunneli-ssh-key"
      ];
    };
  };

  flake.modules.homeManager.tunneli = {
    home.stateVersion = "25.05";
  };
}
