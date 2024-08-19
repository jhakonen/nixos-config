{ pkgs, ... }:
{
  # - Perustuu blogiin https://dataswamp.org/~solene/2022-09-16-netdata-cloud-nixos.html
  # - Historiadata tallennetaan hakemistoon: /var/cache/netdata
  # - Konfiguraatio on polussa: /etc/netdata/netdata.conf
  services.netdata = {
    enable = true;

    # https://github.com/netdata/netdata/blob/master/src/streaming/stream.conf
    configDir."stream.conf" = pkgs.writeText "stream.conf" ''
      [stream]
        enabled = yes
        destination = nassuvm:19999
        api key = b2a07267-adf6-40ae-bfcd-ec24e3d1a68f
    '';

    # https://learn.netdata.cloud/docs/netdata-agent/configuration/daemon-configuration
    # http://kanto:19999/netdata.conf
    config = {
      global = {
        "memory mode" = "none";
        "update every" = 1;
      };
      web.mode = "none";
    };
  };
}
