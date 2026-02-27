{
  den.aspects.dellxps13.nixos = { pkgs, ... }: {
    # Kamera toimii välillä ja välillä ei. Vaikuttaa siltä että minulla tulee
    # tämä bugi vastaan:
    #    https://github.com/intel/ipu6-drivers/issues/291
    # Saattaa olla korjattu kernelissä 6.13.5-arch1-1 ja 6.14.7-arch2-1
    # Kun kamera ei toimi kernelin lokissa näkyy virhe:
    #   deferred probe pending: intel-ipu6: IPU6 bridge init failed
    # Tällöin `cam -l` ei listaa kameraa, ja `qcam` ei näe kameraa.
    # Uudelleen käynnistys saattaa auttaa, tai sitten ei, sattumaa
    #
    # En tiedä varmaksi mitkä näistä asetuksista ovat tarpeellisia kun kamera
    # ei toimi luotettavasti.

    #boot.kernelPackages = pkgs.linuxKernel.packages.latest;

    environment.systemPackages = with pkgs; [
      cheese
      libcamera
      libcamera-qcam
      v4l-utils
    ];

    # https://discourse.nixos.org/t/how-to-hide-this-dummy-video-device/40985
    hardware = {
      enableRedistributableFirmware = true;
      ipu6 = {
        enable = true;
        platform = "ipu6ep";  # Alder/Raptor Lake
      };
    };

    services.pipewire.wireplumber.extraConfig = {
      "wireplumber.profiles" = {
        main = {
          "monitor.v4l2" = "disabled";
          "monitor.libcamera" = "optional";
        };
      };
    };

    # https://github.com/systemd/systemd/commit/fd820e76e4999b4eee13be87fee25f5ffe357a57
    # https://bbs.archlinux.org/viewtopic.php?pid=2199978#p2199978
    services.udev.extraRules = ''
      KERNEL=="udmabuf", TAG+="uaccess"
    '';

    systemd.user.services.pipewire.serviceConfig.RestrictNamespaces = "no";
  };
}
