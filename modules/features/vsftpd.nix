{ self, ... }: let
  pasv_min_port = 10090;
  pasv_max_port = 10100;
in {
  flake.modules.nixos.vsftpd = { config, pkgs, ... }: {
    services.vsftpd = {
      enable = true;
      anonymousUser = true;
      anonymousUploadEnable = true;
      anonymousUmask = "000";
      anonymousUserNoPassword = true;
      extraConfig = ''
        pasv_enable=Yes
        pasv_min_port=${toString pasv_min_port};
        pasv_max_port=${toString pasv_max_port};

        # Salli tiedostojen poisto ja uudelleen nimeäminen
        anon_other_write_enable=Yes
      '';
      writeEnable = true;
    };

    # Avaa palomuuriin palvelulle reikä
    networking.firewall.allowedTCPPorts = [ 21 ];
    networking.firewall.allowedTCPPortRanges = [
      { from = pasv_min_port; to = pasv_max_port; }
    ];
  };
}
