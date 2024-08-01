{ pkgs, ... }:
{
  # - Perustuu blogiin https://dataswamp.org/~solene/2022-09-16-netdata-cloud-nixos.html
  # - Historiadata tallennetaan hakemistoon: /var/cache/netdata
  # - Konfiguraatio on polussa: /etc/netdata/netdata.conf
  services.netdata = {
    enable = true;
    package = pkgs.netdata.override {
      withCloudUi = true;
    };
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
}
