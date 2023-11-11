{ config, pkgs, ... }:
let
  set-custom-res = pkgs.writeScriptBin "set-custom-res" ''
    #!/bin/sh
    kscreen-doctor output.DP-1.mode.''${SUNSHINE_CLIENT_WIDTH}x''${SUNSHINE_CLIENT_HEIGHT}@''${SUNSHINE_CLIENT_FPS}
  '';
in
{
  networking.firewall = {
    allowedTCPPorts = [
      47984 # sunshine https
      47989 # sunshine http
      47990 # sunshine webui
      48010 # sunshine rtsp
    ];
    allowedUDPPorts = [
      47998 # sunshine video
      47999 # sunshine control
      48000 # sunshine audio
      48002 # sunshine mic
    ];
  };

  security.wrappers.sunshine = {
    owner = "root";
    group = "root";
    capabilities = "cap_sys_admin+p";
    source = "${pkgs.sunshine}/bin/sunshine";
  };

  # Tarvitaan hiiren, näppäimistön ja gamepadin simulointiin
  boot.kernelModules = [ "uinput" ];
  services.udev.extraRules = ''
    KERNEL=="uinput", SUBSYSTEM=="misc", OPTIONS+="static_node=uinput", TAG+="uaccess"
  '';

  systemd.user.services.sunshine = {
    enable = true;
    description = "Starts Sunshine";
    wantedBy = ["graphical-session.target"];
    startLimitIntervalSec = 500;
    startLimitBurst = 5;
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = 5;
      ExecStart = "${config.security.wrapperDir}/sunshine";
    };
    path = [
      set-custom-res
      pkgs.libsForQt5.libkscreen  # set-custom-res skriptin riippuvuus
    ];
  };
}
