{
  den.aspects.dellxps13.nixos = { config, pkgs, ... }: {
    environment.systemPackages = [ pkgs.noson ];

    # https://github.com/janbar/noson-app?tab=readme-ov-file#ssdp-discovery-fails
    networking.firewall.extraCommands = ''
      iptables -A nixos-fw -p tcp -s ${config.catalog.nodes.sonos-playbar.ip.private} -j nixos-fw-accept
      iptables -A nixos-fw -p udp -s ${config.catalog.nodes.sonos-playbar.ip.private} -j nixos-fw-accept
    '';

    # Laita logRefusedPackets päälle ja sitten seuraa lokia:
    #   sudo dmesg --follow --human | grep 'refused packet:'
    # networking.firewall.logRefusedPackets = true;
  };
}