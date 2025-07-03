{ inputs, ... }:
{
  flake.modules.nixos.netdata-parent = { config, pkgs, ... }: {
    # - Perustuu blogiin https://dataswamp.org/~solene/2022-09-16-netdata-cloud-nixos.html
    # - Historiadata tallennetaan hakemistoon: /var/cache/netdata
    # - Konfiguraatio on polussa: /etc/netdata/netdata.conf
    services.netdata = {
      enable = true;
      package = pkgs.netdata.override {
        withCloudUi = true;
      };
      # https://github.com/netdata/netdata/blob/master/src/streaming/stream.conf
      configDir."stream.conf" =
        let
          mkChildNode = apiKey: allowFrom: ''
            [${apiKey}]
              enabled = yes
              allow from = ${allowFrom}
          '';
        in pkgs.writeText "stream.conf" ''
          ${mkChildNode "b2a07267-adf6-40ae-bfcd-ec24e3d1a68f" inputs.self.catalog.nodes.kanto.ip.private}
        '';

      # https://learn.netdata.cloud/docs/netdata-agent/configuration/daemon-configuration
      config = {
        global = {
          # uncomment to reduce memory to 32 MB
          #"page cache size" = 32;

          # update interval
          "update every" = 5;
        };
        db."storage tiers" = 3;
        # enable machine learning
        ml.enabled = "yes";
      };
    };

    networking.firewall.allowedTCPPorts = [ 19999 ];
  };
}
