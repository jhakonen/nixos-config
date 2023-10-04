{ pkgs, ... }:
let
  set-custom-res = pkgs.writeScriptBin "set-custom-res" ''
    #!/bin/sh

    # Get params and set any defaults
    width=''${1:-1920}
    height=''${2:-1080}
    refresh_rate=''${3:-60}

    # You may need to adjust the scaling differently so the UI/text isn't too small / big
    scale=''${4:-0.55}

    # Get the name of the active display
    display_output=$(xrandr | grep " connected" | awk '{ print $1 }')

    # Get the modeline info from the 2nd row in the cvt output
    modeline=$(cvt ''${width} ''${height} ''${refresh_rate} | awk 'FNR == 2')
    xrandr_mode_str=''${modeline//Modeline \"*\" /}
    mode_alias="''${width}-''${height}"

    echo "xrandr setting new mode ''${mode_alias} ''${xrandr_mode_str}"
    xrandr --newmode ''${mode_alias} ''${xrandr_mode_str}
    echo "xrandr adding mode ''${mode_alias} to display ''${display_output}"
    xrandr --addmode ''${display_output} ''${mode_alias}

    # Reset scaling
    echo "xrandr reset scaling of ''${display_output}"
    xrandr --output ''${display_output} --scale 1

    # Apply new xrandr mode
    echo "xrandr apply ''${mode_alias} to display ''${display_output} at scale ''${scale}"
    xrandr --output ''${display_output} --primary --mode ''${mode_alias} --pos 0x0 --rotate normal --scale ''${scale}

    # Optional reset your wallpaper to fit to new resolution
    # xwallpaper --zoom /path/to/wallpaper.png
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
      ExecStart = "${pkgs.sunshine}/bin/sunshine";
    };
    path = [ set-custom-res pkgs.xorg.libxcvt ];
  };

  environment.systemPackages = [ set-custom-res pkgs.xorg.libxcvt ];
}
