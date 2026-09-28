{
  den.aspects.fw13pro-audio = {
    nixos = { pkgs, ... }: {
      services.pulseaudio.enable = false;
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;

        # Debug-tulostus
        # wireplumber.extraConfig."log-level"."context.properties"."log.level" = "I";
      };

      # FW13 Pron analoginen ääni ja näytön HDMI/DP-ääni kuuluvat samaan ALSA-
      # korttiin. Kortin vakioprofiilit sallivat vain toisen ulostulon
      # kerrallaan. WirePlumber valitsi automaattisesti
      # output:analog-stereo+input:analog-stereo profiilin joka ei
      # mahdollistanut ulkoisen näytön ulostulon valintaa. Jotta sekä läppärin
      # omat kaiuttimet että ulkoisen näytön kaiuttimet sai molemmat
      # valittaviksi piti tehdä oma yhdistelmäprofiili.
      # Tarkempi selvitys ja kokeillut vaihtoehdot:
      #   docs/fw13pro-audio-investigations.md.
      #
      # PipeWiren ACP:n default.conf määrittelee valmiit analogiset ja HDMI-
      # määritykset ja sisältää lopussa .include 9999-custom.conf -viittauksen.
      # Tuodaan se /etc-hakemistoon, jotta viittaus löytää alla olevan oman
      # profiilin; Nix-storen default.conf sisältäisi sen sijaan paketin oman
      # 9999-custom.conf-tiedoston. ACP etsii /etc-hakemistosta ilman erillisiä
      # ACP_PROFILES_DIR- tai ACP_PATHS_DIR-ympäristömuuttujia.
      environment.etc."alsa-card-profile/mixer/profile-sets/default.conf".source =
        "${pkgs.pipewire}/share/alsa-card-profile/mixer/profile-sets/default.conf";

      # Yhdistelmäprofiili luo erilliset analogisen ja HDMI-ulostulon: läppärin
      # kaiuttimet/kuulokkeet sekä näytön kaiuttimet voidaan valita ilman
      # profiilin vaihtoa. Analoginen mikrofonikin jää käyttöön.
      environment.etc."alsa-card-profile/mixer/profile-sets/9999-custom.conf".text = ''
        [Profile output:analog-stereo+output:hdmi-stereo+input:analog-stereo]
        description = Laptop + Display speakers
        output-mappings = analog-stereo hdmi-stereo
        input-mappings = analog-stereo
      '';

      # Pelkkä yhdistelmäprofiili ei riitä: kuulokkeen kytkeminen tai irrotus
      # läppärin 3,5mm liittimestä mykisti ulkoisen näytön kaiuttimien äänen
      # toiston kesken kaiken, vaikka näytön kaiuttimet pysyivät valittuna.
      # Kuuloke- ja kaiutinpolut tuodaan /etc-hakemistoon, jotta niiden
      # suhteellinen .include löytää alla muokatun analog-output.conf.common-
      # tiedoston samasta hakemistosta. Ilman tätä ne käyttäisivät Nix-storen
      # oletustiedostoa ja mykistäisivät ulkoisen näytön tarvitseman
      # IEC958-kytkimen.
      environment.etc."alsa-card-profile/mixer/paths/analog-output-headphones.conf".source =
        "${pkgs.pipewire}/share/alsa-card-profile/mixer/paths/analog-output-headphones.conf";

      environment.etc."alsa-card-profile/mixer/paths/analog-output-speaker.conf".source =
        "${pkgs.pipewire}/share/alsa-card-profile/mixer/paths/analog-output-speaker.conf";

      # Oletuspolun [Element IEC958] sisältää "switch = off". Portin vaihtuessa
      # se mykistää IEC958,0:n, jolloin näytön ääni lakkaa, kunnes HDMI-laite
      # avataan uudelleen; "amixer -c PCH sset IEC958 unmute" palautti äänen.
      # Vaihdetaan vain tämä asetus muotoon "switch = ignore", jolloin analoginen
      # portinvalinta ja kuulokkeiden/kaiuttimien erilliset äänenvoimakkuudet
      # säilyvät mutta kuulokkeiden irrotius/kytkeminen ei mykistä ulkoisen
      # näytön kaiuttimia.
      environment.etc."alsa-card-profile/mixer/paths/analog-output.conf.common".source =
        pkgs.runCommand "analog-output.conf.common-no-iec958" {} ''
          sed \
            -e '/\[Element IEC958\]/,/^$/ s/switch = off/switch = ignore/' \
            ${pkgs.pipewire}/share/alsa-card-profile/mixer/paths/analog-output.conf.common \
            > $out
        '';

      services.pipewire.wireplumber.extraConfig.main = {
        # Äänilaitteet ja niiden selitteet:
        #   pw-dump | jq -r '.[] | . | select(.type == "PipeWire:Interface:Device") | { name: .info.props."device.name", description: .info.props."device.description" }'
        # Äänilähteet ja niiden selitteet:
        #   pw-dump | jq -r '.[] | . | select(.type == "PipeWire:Interface:Node") | { name: .info.props."node.name", description: .info.props."node.description" }'
        "monitor.alsa.rules" = [
          ({
            matches = [({
              "device.name" = "alsa_card.pci-0000_00_1f.3";
            })];
            # Valitaan yhdistelmäprofiili vain FW13 Pron ALSA-kortille, muuten
            # WirePlumber ottaa käyttöön oletuksena vain yhden ulostulon.
            # WirePlumberin profiilinvalinta (find-best-profile.lua) lukee
            # device.profile -propertyä.
            actions.update-props."device.profile" =
              "output:analog-stereo+output:hdmi-stereo+input:analog-stereo";
          })
          ({
            matches = [({
              "device.name" = "alsa_card.usb-Generic_LGE_37G800A-00";
            })];
            actions.update-props."device.disabled" = true;
          })
          ({
            matches = [({
              "node.name" = "alsa_output.pci-0000_00_1f.3.hdmi-stereo";
            })];
            actions.update-props."node.description" = "Näyttö - Kaiuttimet (HDMI/DP)";
          })
          ({
            matches = [({
              "node.name" = "alsa_output.pci-0000_00_1f.3.analog-stereo";
            })];
            actions.update-props."node.description" = "Läppäri - Kaiuttimet";
          })
          ({
            matches = [({
              "node.name" = "alsa_input.pci-0000_00_1f.3.analog-stereo";
            })];
            actions.update-props."node.description" = "Läppäri - Mikki";
          })
          ({
            matches = [({
              "node.name" = "alsa_input.usb-046d_HD_Pro_Webcam_C920_AF6A0BDF-02.analog-stereo";
            })];
            actions.update-props."node.description" = "Webbikamera - Mikki";
          })
          ({
            matches = [({
              "node.name" = "alsa_output.usb-Lenovo_ThinkPad_Thunderbolt_4_Dock_USB_Audio_000000000000-00.analog-stereo";
            })];
            actions.update-props."node.description" = "Telakka - Kuulokkeet";
          })
          ({
            matches = [({
              "node.name" = "alsa_input.usb-Lenovo_ThinkPad_Thunderbolt_4_Dock_USB_Audio_000000000000-00.mono-fallback";
            })];
            actions.update-props."node.description" = "Telakka - Mikki";
          })
        ];
      };
    };
  };
}
