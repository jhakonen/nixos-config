{ lib, ... }:
let
  user = "jhakonen";
  group = "users";
  downloadDir = "/home/${user}/Lataukset";
in {
  flake.modules.nixos.tailscale = { config, pkgs, ... }: {
    services.tailscale = {
      enable = true;
      extraUpFlags = "--operator=jhakonen";
      openFirewall = true;
    };

    environment.systemPackages = [ pkgs.trayscale ];

    # https://davideger.github.io/blog/taildrop_on_linux
    systemd.services.tailreceive = {
      description = "File Receiver Service for Taildrop";
      wantedBy = [ "multi-user.target" ];
      script = "${lib.getExe config.services.tailscale.package} file get --verbose --loop \"${downloadDir}\"";
      serviceConfig = {
        User = user;
        Group = group;
      };
    };
  };
}
