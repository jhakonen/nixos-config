{
  flake.modules.homeManager.kanshi = { config, pkgs, ... }: {
    home.packages = [
      pkgs.kanshi
      (pkgs.writeShellScriptBin "vaihda-nayttoa" ''
        PROFILE_LINE=$(journalctl --user -u kanshi.service | grep "applied" | tail --lines=1)
        if [[ $PROFILE_LINE == *"-naytto"* ]]; then
          kanshictl switch molemmat-naytot
        else
          kanshictl reload
        fi
      '')
    ];

    # https://gitlab.freedesktop.org/emersion/kanshi/-/blob/master/doc/kanshi.5.scd
    xdg.configFile."kanshi/config" = {
      text = ''
        output DP-1 enable mode 3440x1440 position 0,0

        profile ulkoinen-naytto {
          output eDP-1 disable
          output DP-1 enable
        }

        profile lapparin-naytto {
          output eDP-1 enable
        }

        profile molemmat-naytot {
          output eDP-1 enable
          output DP-1 enable
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
  };
}
