{ inputs, ... }:
{
  flake.modules.nixos.beeper = { pkgs, ... }: {
    environment.systemPackages = [
      pkgs.unstable.beeper
    ];
    systemd.user.services.beeper-fix = {
      enable = true;
      description = "Fix Beeper not starting";
      wantedBy = ["graphical-session.target"];
      serviceConfig.ExecStart = "${pkgs.coreutils}/bin/rm -rf /home/jhakonen/.config/Beeper/GPUCache";
    };
  };
}
