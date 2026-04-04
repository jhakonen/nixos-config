{
  den.aspects.dellxps13.nixos = { pkgs, ... }: {
    environment.systemPackages = [
      pkgs.cherry-studio
      pkgs.lmstudio
      pkgs.unstable.mistral-vibe
      pkgs.unstable.opencode
      pkgs.unstable.opencode-desktop
    ];
  };

  den.aspects.mervi.nixos = { pkgs, ... }: {
    environment.systemPackages = [
      pkgs.unstable.lmstudio
    ];
    networking.firewall.allowedTCPPorts = [ 1234 ];
  };
}
