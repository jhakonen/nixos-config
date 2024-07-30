{
  # https://dataswamp.org/~solene/2022-09-16-netdata-cloud-nixos.html
  services.netdata = {
    enable = true;
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
