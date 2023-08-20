{ pkgs, my-packages, ... }:
{
  systemd.services.gpio-shutdown = {
    description = "gpio-shutdown palvelu";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.bash}/bin/bash -c '${my-packages.wait-button-press}/bin/wait-button-press && shutdown -h now'";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  environment.systemPackages = [ my-packages.wait-button-press ];
}
