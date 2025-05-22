{
  programs.waybar.enable = true;
  programs.waybar.settings.mainBar = {
    # layer = "top"; # Waybar at top layer
    # position = "bottom"; # Waybar position (top|bottom|left|right)
    height = 30; # Waybar height (to be removed for auto height)
    # width = 1280; # Waybar width
    spacing = 4; # Gaps between modules (4px)
    # Choose the order of the modules
    modules-left = [
      "hyprland/workspaces"
      "hyprland/submap"
      # "sway/scratchpad"
      "custom/media"
    ];
    modules-center = [
      "hyprland/window"
    ];
    modules-right = [
      "mpd"
      "idle_inhibitor"
      "pulseaudio"
      "network"
      "power-profiles-daemon"
      "cpu"
      "memory"
      "temperature"
      "backlight"
      "keyboard-state"
      "hyprland/language"
      "battery"
      # "battery#bat2"
      "clock"
      "tray"
      "custom/power"
    ];

    # Modules configuration

    # "hyprland/workspaces" = {
    #   disable-scroll = true;
    #   all-outputs = true;
    #   warp-on-scroll = false;
    #   format = "{name}: {icon}";
    #   format-icons = {
    #     "1" = "";
    #     "2" = "";
    #     "3" = "";
    #     "4" = "";
    #     "5" = "";
    #     urgent = "";
    #     focused = "";
    #     default = "";
    #   };
    # };
    keyboard-state = {
      numlock = true;
      capslock = true;
      format = "{name} {icon}";
      format-icons = {
        locked = "";
        unlocked = "";
      };
    };
    "hyprland/submap" = {
      format = "<span style=\"italic\">{}</span>";
    };
    # "sway/scratchpad" = {
    #   format = "{icon} {count}";
    #   show-empty = false;
    #   format-icons = ["" ""];
    #   tooltip = true;
    #   tooltip-format = "{app}: {title}";
    # };
    mpd = {
      format = "{stateIcon} {consumeIcon}{randomIcon}{repeatIcon}{singleIcon}{artist} - {album} - {title} ({elapsedTime:%M:%S}/{totalTime:%M:%S}) ⸨{songPosition}|{queueLength}⸩ {volume}% ";
      format-disconnected = "Disconnected ";
      format-stopped = "{consumeIcon}{randomIcon}{repeatIcon}{singleIcon}Stopped ";
      unknown-tag = "N/A";
      interval = 5;
      consume-icons = {
        on = " ";
      };
      random-icons = {
        off = "<span color=\"#f53c3c\"></span> ";
        on = " ";
      };
      repeat-icons = {
        on = " ";
      };
      single-icons = {
        on = "1 ";
      };
      state-icons = {
        paused = "";
        playing = "";
      };
      tooltip-format = "MPD (connected)";
      tooltip-format-disconnected = "MPD (disconnected)";
    };
    idle_inhibitor = {
      format = "{icon}";
      format-icons = {
        activated = "";
        deactivated = "";
      };
    };
    tray = {
      # icon-size = 21;
      spacing = 10;
    };
    clock = {
      # timezone = "America/New_York";
      tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
      format-alt = "{:%Y-%m-%d}";
    };
    cpu = {
      format = "{usage}% ";
      tooltip = false;
    };
    memory = {
      format = "{}% ";
    };
    temperature = {
      # thermal-zone = 2;
      # hwmon-path = "/sys/class/hwmon/hwmon2/temp1_input";
      critical-threshold = 80;
      # format-critical = "{temperatureC}°C {icon}";
      format = "{temperatureC}°C {icon}";
      format-icons = ["" "" ""];
    };
    backlight = {
      # device = "acpi_video1";
      format = "{percent}% {icon}";
      format-icons = ["" "" "" "" "" "" "" "" ""];
    };
    battery = {
      states = {
        # good = 95,
        warning = 30;
        critical = 15;
      };
      format = "{capacity}% {icon}";
      format-full = "{capacity}% {icon}";
      format-charging = "{capacity}% ";
      format-plugged = "{capacity}% ";
      format-alt = "{time} {icon}";
      # format-good = ""; # An empty format will hide the module
      # format-full = "";
      format-icons = ["" "" "" "" ""];
    };
    # "battery#bat2" = {
    #   bat = "BAT2";
    # };
    power-profiles-daemon = {
      format = "{icon}";
      tooltip-format = "Power profile: {profile}\nDriver: {driver}";
      tooltip = true;
      format-icons = {
        default = "";
        performance = "";
        balanced = "";
        power-saver = "";
      };
    };
    network = {
      # interface = "wlp2*", # (Optional) To force the use of this interface
      format-wifi = "{essid} ({signalStrength}%) ";
      format-ethernet = "{ipaddr}/{cidr} ";
      tooltip-format = "{ifname} via {gwaddr} ";
      format-linked = "{ifname} (No IP) ";
      format-disconnected = "Disconnected ⚠";
      format-alt = "{ifname}: {ipaddr}/{cidr}";
    };
    pulseaudio = {
      # scroll-step = 1, # %, can be a float
      format = "{volume}% {icon} {format_source}";
      format-bluetooth = "{volume}% {icon} {format_source}";
      format-bluetooth-muted = " {icon} {format_source}";
      format-muted = " {format_source}";
      format-source = "{volume}% ";
      format-source-muted = "";
      format-icons = {
        headphone = "";
        hands-free = "";
        headset = "";
        phone = "";
        portable = "";
        car = "";
        default = ["" "" ""];
      };
      on-click = "pavucontrol";
    };
    "custom/media" = {
      format = "{icon} {}";
      return-type = "json";
      max-length = 40;
      format-icons = {
        spotify = "";
        default = "🎜";
      };
      escape = true;
      exec = "$HOME/.config/waybar/mediaplayer.py"; # Script in resources folder
      # exec = "$HOME/.config/waybar/mediaplayer.py --player spotify 2> /dev/null"; # Filter player based on name
    };
    "custom/power" = {
      format = "⏻ ";
      tooltip = false;
      menu = "on-click";
      menu-file = "$HOME/.config/waybar/power_menu.xml"; # Menu file in resources folder
      menu-actions = {
        shutdown = "shutdown now";
        reboot = "reboot";
        suspend = "systemctl suspend";
        hibernate = "systemctl hibernate";
        logout = "/run/current-system/sw/bin/hyprctl dispatch exit";
      };
    };
  }; # end of waybar settings

  programs.waybar.style = ''
    * {
        /* `otf-font-awesome` is required to be installed for icons */
        font-family: FontAwesome, Roboto, Helvetica, Arial, sans-serif;
        font-size: 13px;
    }

    window#waybar {
        background-color: rgba(43, 48, 59, 0.5);
        border-bottom: 3px solid rgba(100, 114, 125, 0.5);
        color: #ffffff;
        transition-property: background-color;
        transition-duration: .5s;
    }

    window#waybar.hidden {
        opacity: 0.2;
    }

    /*
    window#waybar.empty {
        background-color: transparent;
    }
    window#waybar.solo {
        background-color: #FFFFFF;
    }
    */

    window#waybar.termite {
        background-color: #3F3F3F;
    }

    window#waybar.chromium {
        background-color: #000000;
        border: none;
    }

    button {
        /* Use box-shadow instead of border so the text isn't offset */
        box-shadow: inset 0 -3px transparent;
        /* Avoid rounded borders under each button name */
        border: none;
        border-radius: 0;
    }

    /* https://github.com/Alexays/Waybar/wiki/FAQ#the-workspace-buttons-have-a-strange-hover-effect */
    button:hover {
        background: inherit;
        box-shadow: inset 0 -3px #ffffff;
    }

    /* you can set a style on hover for any module like this */
    #pulseaudio:hover {
        background-color: #a37800;
    }

    #workspaces button {
        padding: 0 5px;
        background-color: transparent;
        color: #ffffff;
    }

    #workspaces button:hover {
        background: rgba(0, 0, 0, 0.2);
    }

    #workspaces button.focused {
        background-color: #64727D;
        box-shadow: inset 0 -3px #ffffff;
    }

    #workspaces button.urgent {
        background-color: #eb4d4b;
    }

    #mode {
        background-color: #64727D;
        box-shadow: inset 0 -3px #ffffff;
    }

    #clock,
    #battery,
    #cpu,
    #memory,
    #disk,
    #temperature,
    #backlight,
    #network,
    #pulseaudio,
    #wireplumber,
    #custom-media,
    #tray,
    #mode,
    #idle_inhibitor,
    #scratchpad,
    #power-profiles-daemon,
    #mpd {
        padding: 0 10px;
        color: #ffffff;
    }

    #window,
    #workspaces {
        margin: 0 4px;
    }

    /* If workspaces is the leftmost module, omit left margin */
    .modules-left > widget:first-child > #workspaces {
        margin-left: 0;
    }

    /* If workspaces is the rightmost module, omit right margin */
    .modules-right > widget:last-child > #workspaces {
        margin-right: 0;
    }

    #clock {
        background-color: #64727D;
    }

    #battery {
        background-color: #ffffff;
        color: #000000;
    }

    #battery.charging, #battery.plugged {
        color: #ffffff;
        background-color: #26A65B;
    }

    @keyframes blink {
        to {
            background-color: #ffffff;
            color: #000000;
        }
    }

    /* Using steps() instead of linear as a timing function to limit cpu usage */
    #battery.critical:not(.charging) {
        background-color: #f53c3c;
        color: #ffffff;
        animation-name: blink;
        animation-duration: 0.5s;
        animation-timing-function: steps(12);
        animation-iteration-count: infinite;
        animation-direction: alternate;
    }

    #power-profiles-daemon {
        padding-right: 15px;
    }

    #power-profiles-daemon.performance {
        background-color: #f53c3c;
        color: #ffffff;
    }

    #power-profiles-daemon.balanced {
        background-color: #2980b9;
        color: #ffffff;
    }

    #power-profiles-daemon.power-saver {
        background-color: #2ecc71;
        color: #000000;
    }

    label:focus {
        background-color: #000000;
    }

    #cpu {
        background-color: #2ecc71;
        color: #000000;
    }

    #memory {
        background-color: #9b59b6;
    }

    #disk {
        background-color: #964B00;
    }

    #backlight {
        background-color: #90b1b1;
    }

    #network {
        background-color: #2980b9;
    }

    #network.disconnected {
        background-color: #f53c3c;
    }

    #pulseaudio {
        background-color: #f1c40f;
        color: #000000;
    }

    #pulseaudio.muted {
        background-color: #90b1b1;
        color: #2a5c45;
    }

    #wireplumber {
        background-color: #fff0f5;
        color: #000000;
    }

    #wireplumber.muted {
        background-color: #f53c3c;
    }

    #custom-media {
        background-color: #66cc99;
        color: #2a5c45;
        min-width: 100px;
    }

    #custom-media.custom-spotify {
        background-color: #66cc99;
    }

    #custom-media.custom-vlc {
        background-color: #ffa000;
    }

    #temperature {
        background-color: #f0932b;
    }

    #temperature.critical {
        background-color: #eb4d4b;
    }

    #tray {
        background-color: #2980b9;
    }

    #tray > .passive {
        -gtk-icon-effect: dim;
    }

    #tray > .needs-attention {
        -gtk-icon-effect: highlight;
        background-color: #eb4d4b;
    }

    #idle_inhibitor {
        background-color: #2d3436;
    }

    #idle_inhibitor.activated {
        background-color: #ecf0f1;
        color: #2d3436;
    }

    #mpd {
        background-color: #66cc99;
        color: #2a5c45;
    }

    #mpd.disconnected {
        background-color: #f53c3c;
    }

    #mpd.stopped {
        background-color: #90b1b1;
    }

    #mpd.paused {
        background-color: #51a37a;
    }

    #language {
        background: #00b093;
        color: #740864;
        padding: 0 5px;
        margin: 0 5px;
        min-width: 16px;
    }

    #keyboard-state {
        background: #97e1ad;
        color: #000000;
        padding: 0 0px;
        margin: 0 5px;
        min-width: 16px;
    }

    #keyboard-state > label {
        padding: 0 5px;
    }

    #keyboard-state > label.locked {
        background: rgba(0, 0, 0, 0.2);
    }

    #scratchpad {
        background: rgba(0, 0, 0, 0.2);
    }

    #scratchpad.empty {
      background-color: transparent;
    }

    #privacy {
        padding: 0;
    }

    #privacy-item {
        padding: 0 5px;
        color: white;
    }

    #privacy-item.screenshare {
        background-color: #cf5700;
    }

    #privacy-item.audio-in {
        background-color: #1ca000;
    }

    #privacy-item.audio-out {
        background-color: #0069d4;
    }
  ''; # end of waybar style
  xdg.configFile."waybar/power_menu.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <interface>
      <object class="GtkMenu" id="menu">
        <child>
        <object class="GtkMenuItem" id="suspend">
          <property name="label">Suspend</property>
            </object>
      </child>
      <child>
            <object class="GtkMenuItem" id="hibernate">
          <property name="label">Hibernate</property>
            </object>
      </child>
        <child>
            <object class="GtkMenuItem" id="shutdown">
          <property name="label">Shutdown</property>
            </object>
        </child>
        <child>
          <object class="GtkSeparatorMenuItem" id="delimiter1"/>
        </child>
        <child>
        <object class="GtkMenuItem" id="reboot">
          <property name="label">Reboot</property>
        </object>
        </child>
        <child>
        <object class="GtkMenuItem" id="logout">
          <property name="label">Log out</property>
        </object>
        </child>
      </object>
    </interface>
  '';
}
