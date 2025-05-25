{ config, pkgs, ... }:
{
  home.packages = [ pkgs.kanshi ];

  # https://gitlab.freedesktop.org/emersion/kanshi/-/blob/master/doc/kanshi.5.scd
  xdg.configFile."kanshi/config" = {
    text = ''
      profile telakassa {
        output eDP-1 disable
        output DP-1 enable mode 3440x1440 position 0,0
      }
      profile irti {
        output eDP-1 enable
      }
    '';
    onChange = ''
      ${pkgs.procps}/bin/pkill -u $USER -HUP kanshi || true
    '';
  };


  systemd.user.services.kanshi = {
    Unit = {
      PartOf = [
        config.wayland.systemd.target
      ];
      After = [ config.wayland.systemd.target ];
    };

    Service = {
      ExecStart = "${pkgs.kanshi}/bin/kanshi";
      Restart = "on-failure";
    };

    Install.WantedBy = [
      config.wayland.systemd.target
    ];
  };
}
