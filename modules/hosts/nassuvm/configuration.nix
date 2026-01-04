# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{ inputs, ... }:
{
  flake.modules.nixos.nassuvm = { config, pkgs, ... }: {
    # Ota flaket käyttöön
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    imports = [
      inputs.agenix.nixosModules.default
      inputs.home-manager.nixosModules.home-manager

      inputs.self.modules.nixos.service-restic

      inputs.self.modules.nixos.common
      inputs.self.modules.nixos.nginx
      inputs.self.modules.nixos.nix-cleanup
      inputs.self.modules.nixos.tailscale
    ];

    boot.loader.grub.enable = true;
    boot.loader.grub.device = "/dev/sda";
    boot.loader.grub.useOSProber = true;

    # Hallitse verkkoyhteyttä NetworkManagerilla
    networking.networkmanager.enable = true;

    services.xserver.enable = true;
    services.xserver.displayManager.lightdm.enable = true;
    services.xserver.desktopManager.xfce.enable = true;

    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    nixpkgs.config.allowUnfree = true;

    environment.systemPackages = with pkgs; [
      firefox
      simplescreenrecorder
    ];

    # Ota Let's Encryptin sertifikaatti käyttöön
    security.acme.certs."nassuvm.lan.jhakonen.com".extraDomainNames = [
      "*.nassuvm.lan.jhakonen.com"
    ];

    system.stateVersion = "23.05";
  };

  flake.modules.homeManager.nassuvm = {
    # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
    home.stateVersion = "24.05";
  };
}
