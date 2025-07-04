# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{ inputs, ... }:
{
  flake.modules.nixos.nassuvm = { config, pkgs, ... }: {
    # Ota flaket käyttöön
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    imports = [
      inputs.home-manager.nixosModules.home-manager

      inputs.self.modules.nixos.common
      inputs.self.modules.nixos.koti
      inputs.self.modules.nixos.netdata-parent
      inputs.self.modules.nixos.nix-cleanup
      inputs.self.modules.nixos.zsh
    ];

    boot.loader.grub.enable = true;
    boot.loader.grub.device = "/dev/sda";
    boot.loader.grub.useOSProber = true;

    networking.hostName = "nassuvm";

    networking.networkmanager.enable = true;

    time.timeZone = "Europe/Helsinki";

    i18n.defaultLocale = "fi_FI.UTF-8";
    i18n.extraLocaleSettings = {
      LC_ADDRESS = "fi_FI.UTF-8";
      LC_IDENTIFICATION = "fi_FI.UTF-8";
      LC_MEASUREMENT = "fi_FI.UTF-8";
      LC_MONETARY = "fi_FI.UTF-8";
      LC_NAME = "fi_FI.UTF-8";
      LC_NUMERIC = "fi_FI.UTF-8";
      LC_PAPER = "fi_FI.UTF-8";
      LC_TELEPHONE = "fi_FI.UTF-8";
      LC_TIME = "fi_FI.UTF-8";
    };

    services.xserver.enable = true;
    services.xserver.displayManager.lightdm.enable = true;
    services.xserver.desktopManager.xfce.enable = true;

    services.xserver = {
      xkb.layout = "fi";
      xkb.variant = "nodeadkeys";
    };

    console.keyMap = "fi";

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

    services.openssh = {
      enable = true;
      settings = {
        # Vaadi SSH sisäänkirjautuminen käyttäen vain yksityistä avainta
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };

    system.stateVersion = "23.05";
  };

  flake.modules.homeManager.nassuvm = {
    # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
    home.stateVersion = "24.05";
  };
}
