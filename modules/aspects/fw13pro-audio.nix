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

        # Näytön kaiuttimet tulevat DisplayPort-audiona (eikä USB:na), mutta
        # WirePlumber ei generoi HDMI/DP-profiiilia Frameworkin (Panther Lake)
        # HDA-kortille (00:1f.3). Pakota siksi sinkki suoraan ALSA PCM:ään, joka
        # kantaa LV:n LG-näytön aktiivista ELD:ää: card 0, device 7 ("HDMI 1").
        # Tarkista/aina: cat /proc/asound/card0/pcm7p/sub0/info  ja
        #   ls /proc/asound/card0/eld*  (jossa monitor_present = 1).
        # extraConfig.pipewire."70-dp-sink.conf" = {
        #   "context.objects" = [
        #     {
        #       factory = "adapter";
        #       args = {
        #         "factory.name" = "api.alsa.pcm.sink";
        #         "node.name" = "alsa_output.dp-lg-377";
        #         "node.description" = "LG 37G800A (HDMI/DP)";
        #         "media.class" = "Audio/Sink";
        #         "api.alsa.path" = "hw:0,7";
        #         "api.alsa.period-size" = 1024;
        #         "api.alsa.headroom" = 0;
        #         "api.alsa.disable-mmap" = false;
        #         "api.alsa.disable-batch" = false;
        #         "audio.format" = "S16LE";
        #         "audio.rate" = 48000;
        #         "audio.channels" = 2;
        #         "audio.position" = [ "FL" "FR" ];
        #       };
        #     }
        #   ];
        # };
      };

      # Näytön kaiuttimet tulevat DisplayPort-audiona Intelin HDMI-koodekille
      # (HDA-kortti "PCH", codec#2) ja läppärin omat kaiuttimet ovat ALC285-
      # koodekin analogisessa profiilissa. ACP/ WirePlumber pitää vain yhtä
      # profiilia päällä kerrallaan, ja oletusprioriteetilla analoginen
      # profiili (läppärin kaiuttimet) voittaa HDMI-profiilin.
      #
      # Profiilin oletusvalinta määritellään deklaratiivisesti alla: kun näyttö
      # on kytkettynä valitaan HDMI-profiili (näytön kaiuttimet), muuten läppärin
      # kaiuttimet (analog-stereo). "device.restore-profile" = false estää
      # muistista palauttamisen, jotta säännöt ovat aina voimassa myös kuuman
      # kytkennän jälkeen (profiilivalintoja ei siis tallenneta).
      services.pipewire.wireplumber.extraConfig.main = {
        "wireplumber.settings" = {
          "device.restore-profile" = false;
        };
        "device.profile.priority.rules" = [
          ({
            matches = [({
              "device.name" = "alsa_card.pci-0000_00_1f.3";
            })];
            actions.update-props.priorities = [
              "output:hdmi-stereo+input:analog-stereo"    # Näytön kaiuttimet
              "output:analog-stereo+input:analog-stereo"  # Läppärin kaiuttimet
            ];
          })
        ];

        "monitor.alsa.rules" = [
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
              "node.name" = "alsa_output.usb-CalDigit__Inc._CalDigit_Thunderbolt_3_Audio-00.analog-stereo";
            })];
            actions.update-props."node.description" = "Telakka - Kaiuttimet";
          })
          ({
            matches = [({
                "node.name" = "alsa_input.usb-CalDigit__Inc._CalDigit_Thunderbolt_3_Audio-00.analog-stereo";
            })];
            actions.update-props."node.description" = "Telakka - Mikki";
          })
          ({
            matches = [({
              "node.name" = "alsa_input.usb-046d_HD_Pro_Webcam_C920_AF6A0BDF-02.analog-stereo";
            })];
            actions.update-props."node.description" = "Webbikamera - Mikki";
          })
        ];
      };

      # Yllä olevat prioriteettisäännöt pakottavat HDMI-profiilin, kun näyttö
      # on kytkettynä. Jos tuolloin kuulokkeet kytketään läppärin 3,5 mm-
      # liittimeen, HDMI-profiilissa ei ole lainkaan analogista *ulostuloa*,
      # joten analoginen ulostulosolmu jää "orvoksi" (ei aktiivista reittiä eikä
      # oikein konfiguroitua äänenvoimakkuuspolkua) ja kuulokkeista kuuluu vain
      # hiljaista ääntä. Tämä palvelu kysyy 2 sekunnin välein PipeWireltä
      # (pw-dump) reittien jack-tilat ja vaihtaa profiilin analogiseksi aina,
      # kun kuulokeliitin on käytössä. Kun kuulokkeet irrotetaan, palataan
      # prioriteettisääntöjen mukaiseen valintaan (HDMI-profiili, jos näyttö
      # on kytkettynä).
      # systemd.user.services: palvelun pitää nähdä käyttäjän PipeWire-istunto
      # (pw-dump tarvitsee XDG_RUNTIME_DIR:n), joten se ajetaan käyttäjänä
      # eikä root-järjestelmäpalveluna.
      systemd.user.services.audio-jack-profile = {
        description = "Äänikortin profiilin vaihto kuulokeliittimen mukaan";
        after = [ "wireplumber.service" ];
        wants = [ "wireplumber.service" ];
        wantedBy = [ "default.target" ];
        serviceConfig = {
          ExecStart = pkgs.writers.writePython3 "audio-jack-profile" {
            flakeIgnore = ["E501"];
          } ''
            import json
            import subprocess
            import time

            DEVICE = "alsa_card.pci-0000_00_1f.3"
            ANALOG = "output:analog-stereo+input:analog-stereo"
            HDMI = "output:hdmi-stereo+input:analog-stereo"
            POLL = 2


            def run(*args):
                return subprocess.run(args, capture_output=True, text=True,
                                      errors="replace").stdout


            def card_state():
                """Kortin tila pw-dumpista.

                Palauttaa (objektin id, {profiili: indeksi}, nykyinen profiili,
                kuulokeliitin kytketty, HDMI/DP kytketty) tai None, jos
                korttia ei näy (esim. WirePlumber ei ole vielä valmistunut).

                Liittimien tila luetaan reittien (Route/EnumRoute)
                "available"-kentästä: "yes" tarkoittaa, että liitin on
                kytkettynä. "Route" sisältää vain aktiivisen profiilin
                reitit, joten kuulokeliittimen tilaa haetaan myös
                "EnumRoute":sta (listaa kaikkien profiilien reitit).
                """
                try:
                    objs = json.loads(run("pw-dump"))
                except (json.JSONDecodeError, ValueError):
                    return None
                for o in objs:
                    if o.get("type") != "PipeWire:Interface:Device":
                        continue
                    props = o.get("info", {}).get("props", {})
                    if props.get("device.name") != DEVICE:
                        continue
                    params = o["info"].get("params", {})
                    profiles = {p["name"]: p["index"]
                                for p in params.get("EnumProfile", [])}
                    cur = params.get("Profile", [{}])[0].get("name")
                    plugged = {}
                    for key in ("Route", "EnumRoute"):
                        for route in params.get(key, []):
                            name = route.get("name", "")
                            available = route.get("available")
                            if available == "unknown" and name == "analog-output-headphones":
                                plugged["headphone"] = True
                            elif available == "yes" and name.startswith("hdmi-output"):
                                plugged["hdmi"] = True
                    return (o["id"], profiles, cur,
                            plugged.get("headphone", False),
                            plugged.get("hdmi", False))
                return None


            def apply():
                """Vaihda profiili liittimien tilan mukaiseksi, jos se on
                väärä."""
                state = card_state()
                if state is None:
                    return
                obj_id, profiles, cur, headphone, hdmi = state
                if headphone:
                    want = ANALOG
                elif hdmi:
                    want = HDMI
                else:
                    want = ANALOG
                if want in profiles and cur != want:
                    subprocess.run(["wpctl", "set-profile", str(obj_id),
                                    str(profiles[want])])


            def main():
                # Odota, että WirePlumber näkee äänikortin.
                while card_state() is None:
                    time.sleep(POLL)

                # Kysy liittimien tilaa säännöllisesti pw-dumpista. Pieni
                # viive ennen profiilin vaihtoa antaa WirePlumberille aikaa
                # käsitellä tapahtuma ensin, joten lopullinen profiilivalinta
                # on tämän skriptin.
                while True:
                    time.sleep(POLL)
                    apply()


            main()
          '';
          Restart = "on-failure";
          RestartSec = "2s";
        };
        # Skriptin tarvitsemat ulkoiset työkalut: pw-dump, wpctl.
        path = with pkgs; [
          wireplumber
          pipewire
        ];
      };
    };
  };
}
