{ config, lib, pkgs, ... }:
let
  # Helper utility for launching Steam games from Sunshine. This works around
  # issue where Sunshine's security wrapper prevents Steam from launching.
  # Examples:
  #   steam-run-url steam://rungameid/1086940  # Start Baldur's Gate 3
  #   steam-run-url steam://open/bigpicture    # Start Steam in Big Picture mode
  steam-run-url = pkgs.writeShellApplication {
    name = "steam-run-url";
    text = ''
      echo "$1" > "/run/user/$(id --user)/steam-run-url.fifo"
    '';
    runtimeInputs = [
      pkgs.coreutils  # For `id` command
    ];
  };
in
{
  services.sunshine = {
    enable = true;
    openFirewall = true;
    capSysAdmin = true;  # Use security wrapper, required with Wayland
  };

  # Allow running `steam-run-url` from Sunshine without knowing the script's
  # absolute file path
  systemd.user.services.sunshine.path = [
    steam-run-url
  ];

  systemd.user.services.sunshine.environment = {
    AMD_DEBUG = "lowlatencyenc";
  };

  # Allow running `steam-run-url` from shell for testing purposes
  environment.systemPackages = [ steam-run-url ];

  # Service part for `steam-run-url`. This listens for Steam urls from a named
  # pipe (typically at path `/run/user/1000/steam-run-url.fifo`) and then
  # launches Steam, passing the url to it.
  systemd.user.services.steam-run-url-service = {
    enable = true;
    description = "Listen and starts steam games by id";
    wantedBy = ["graphical-session.target"];
    partOf = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig.Restart = "on-failure";
    script = toString (pkgs.writers.writePython3 "steam-run-url-service" {} ''
      import os
      from pathlib import Path
      import subprocess

      pipe_path = Path(f'/run/user/{os.getuid()}/steam-run-url.fifo')
      try:
          pipe_path.parent.mkdir(parents=True, exist_ok=True)
          pipe_path.unlink(missing_ok=True)
          os.mkfifo(pipe_path, 0o600)
          while True:
              with pipe_path.open(encoding='utf-8') as pipe:
                  subprocess.Popen(['steam', pipe.read().strip()])
      finally:
          pipe_path.unlink(missing_ok=True)
    '');
    path = [
      pkgs.gamemode
      pkgs.steam
    ];
  };
}
