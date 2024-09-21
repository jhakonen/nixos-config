{ config, lib, pkgs, ... }:
let
  STEAM_RUNNER_PORT = 48753;
  steam-run-id = pkgs.writeShellApplication {
    name = "steam-run-id";
    text = ''
      echo "$1" | ${lib.getExe pkgs.netcat-gnu} localhost ${toString STEAM_RUNNER_PORT}
    '';
  };

  set-custom-res = pkgs.writeScriptBin "set-custom-res" ''
    #!/bin/sh
    kscreen-doctor output.DP-1.mode.''${SUNSHINE_CLIENT_WIDTH}x''${SUNSHINE_CLIENT_HEIGHT}@''${SUNSHINE_CLIENT_FPS}
  '';
in
{
  services.sunshine = {
    enable = true;
    openFirewall = true;
    capSysAdmin = true;
  };

  systemd.user.services.sunshine.path = [
    set-custom-res
    pkgs.libsForQt5.libkscreen  # set-custom-res skriptin riippuvuus
    #pkgs.steam
    #pkgs.util-linux  # setsid
    steam-run-id
  ];

  environment.systemPackages = with pkgs; [
    steam-run-id
  ];

  systemd.user.services.steam-id-runner = let
    # runner-service = pkgs.writeShellApplication {
    #   name = "steam-run-id-service";
    #   text = ''
    #     read -r steamid
    #     re='^[0-9]+$'
    #     if ! [[ $steamid =~ $re ]] ; then
    #        echo "error: Not a steam id" >&2; exit 1
    #     fi
    #     ${pkgs.coreutils}/bin/nohup ${lib.getExe pkgs.steam} "steam://rungameid/$steamid" &
    #     ${pkgs.coreutils}/bin/sleep 5
    #   '';
    # };

    runner-service = pkgs.writers.writePython3 "steam-run-id-service" { flakeIgnore = ["E111" "E302" "E305" "E501"]; } ''
      import socketserver
      import subprocess

      class MyTCPHandler(socketserver.BaseRequestHandler):
        def handle(self):
          steam_id = self.request.recv(1024).decode('utf-8').strip()
          if not steam_id.isdigit():
            raise RuntimeError('Not a steam id')
          self.steam_process = subprocess.Popen(['${lib.getExe pkgs.steam}', f'steam://rungameid/{steam_id}'])

      with socketserver.TCPServer(('localhost', ${toString STEAM_RUNNER_PORT}), MyTCPHandler) as server:
        server.serve_forever()
    '';
  in {
    enable = true;
    description = "Listen and starts steam apps by id";
    wantedBy = ["graphical-session.target"];
    serviceConfig = {
      Restart = "always";
    };
    # script = ''
    #   ${lib.getExe pkgs.netcat-gnu} -l -p ${toString STEAM_RUNNER_PORT} -e ${lib.getExe runner-service}
    # '';
    script = "${runner-service}";
  };

  # Ei toimi vielä: https://github.com/systemd/systemd/issues/33167
  # https://github.com/systemd/systemd/commit/0e5c97ae6f16b2d33b341e17e1236c605fde2410
  # systemd.user.services.sunshine.serviceConfig.AmbientCapabilities = [
  #   "CAP_SYS_ADMIN"
  # ];

  # Ei toimi systemd 255:n kanssa
  # nixpkgs.overlays = [
  #   (final: prev: {
  #     systemd = prev.systemd.overrideAttrs (o: {
  #       patches = (o.patches or [ ]) ++ [
  #         (pkgs.fetchurl {
  #           url = "https://github.com/systemd/systemd/commit/0e5c97ae6f16b2d33b341e17e1236c605fde2410.diff";
  #           hash = "sha256-QlIEa6WyU6RiBXMXYaJgtqlsZz1iidzR+SQcZ8SesAQ=";
  #         })
  #       ];
  #     });
  #   })
  # ];

}
