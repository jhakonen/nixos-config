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

        wireplumber.extraConfig."log-level"."context.properties"."log.level" = "I";

        # wireplumber = {
        #   extraConfig."99-fw13pro-audio" = {
        #     "wireplumber.components" = [
        #       # {
        #       #   name = "fw13pro-audio/disable-default-profile.lua";
        #       #   type = "script/lua";
        #       #   provides = "fw13pro-audio.disable-default-profile";
        #       # }
        #       {
        #         name = "fw13pro-audio/profile-select.lua";
        #         type = "script/lua";
        #         provides = "fw13pro-audio.profile-select";
        #       }
        #     ];
        #     # "wireplumber.profiles".main."fw13pro-audio.disable-default-profile" = "required";
        #     "wireplumber.profiles".main."fw13pro-audio.profile-select" = "required";
        #   };
        #   # extraScripts."fw13pro-audio/disable-default-profile.lua" = ''

        #   # '';
        #   extraScripts."fw13pro-audio/profile-select.lua" = ''
        #     cutils = require ("common-utils")

        #     DEVICE = "alsa_card.pci-0000_00_1f.3"
        #     PROFILE_ANALOG = "output:analog-stereo+input:analog-stereo"
        #     PROFILE_DISPLAY = "output:hdmi-stereo+input:analog-stereo"

        #     function get_device_profile (device)
        #       for p in device:iterate_params("Profile") do
        #         return cutils.parseParam (p, "Profile")
        #       end
        #     end

        #     SimpleEventHook {
        #       name = "fw13pro-audio/block-default-profile",
        #       before = { "device/apply-profile" },
        #       interests = {
        #         EventInterest {
        #           Constraint { "event.type", "=", "select-profile" },
        #           Constraint { "device.name", "=", DEVICE },
        #         },
        #       },
        #       execute = function (event)
        #         local device = event:get_subject ()
        #         local profile = get_device_profile (device)

        #         print("####################### BLOCKER profile", profile.name)

        #         if profile.name ~= "off" then
        #           print("####################### BLOCKER Blocking processing")
        #           event:stop_processing ()
        #         end
        #       end
        #     }:register ()

        #     AsyncEventHook {
        #       name = "fw13pro-audio/profile-select",
        #       interests = {
        #         EventInterest {
        #           Constraint { "event.type", "=", "device-params-changed" },
        #           Constraint { "device.name", "=", DEVICE },
        #         },
        #       },
        #       steps = {
        #         start = {
        #           next = "none",
        #           execute = function (event, transition)
        #             local device = event:get_subject ()
        #             local active_profile_name = get_device_profile(device).name
        #             local plugged_hdmi = false
        #             local plugged_headphones = false
        #             local device_name = device.properties["device.name"]
        #             local wants_profile_index = nil
        #             local wants_profile_name = nil

        #             for p in device:iterate_params("EnumRoute") do
        #               local route = cutils.parseParam (p, "EnumRoute")
        #               if route.name == "analog-output-headphones" and route.available ~= "no" then
        #                 plugged_headphones = true
        #               end
        #               if string.find(route.name, "hdmi-output", 1, true) and route.available == "yes" then
        #                 plugged_hdmi = true
        #               end
        #             end

        #             print("plugged_headphones=", plugged_headphones, ", plugged_hdmi=", plugged_hdmi)

        #             if plugged_headphones then
        #               wants_profile_name = PROFILE_ANALOG
        #             elseif plugged_hdmi then
        #               wants_profile_name = PROFILE_DISPLAY
        #             else
        #               wants_profile_name = PROFILE_ANALOG
        #             end

        #             if active_profile_name ~= wants_profile_name then
        #               for p in device:iterate_params("EnumProfile") do
        #                 local profile = cutils.parseParam (p, "EnumProfile")
        #                 if profile.name == wants_profile_name then
        #                   wants_profile_index = tonumber(profile.index)
        #                   break
        #                 end
        #               end
        #             end

        #             -- print("active_profile_name=", active_profile_name)
        #             -- print("wants_profile_name=", wants_profile_name)
        #             -- print("wants_profile_index=", wants_profile_index)

        #             if wants_profile_index == nil then
        #               transition:advance ()
        #             else
        #               print("Switching profile of", device_name, "::", active_profile_name, "-->", wants_profile_name)
        #               local param = Pod.Object {
        #                 "Spa:Pod:Object:Param:Profile",
        #                 "Profile",
        #                 index = wants_profile_index,
        #               }
        #               device:set_param ("Profile", param)

        #               Core.sync (function ()
        #                 transition:advance ()
        #               end)
        #             end
        #           end -- execute
        #         },
        #       },
        #     }:register ()
        #   '';
        # };
      };

      environment.etc."alsa-card-profile/mixer/profile-sets/default.conf".source = "${pkgs.pipewire}/share/alsa-card-profile/mixer/profile-sets/default.conf";

      systemd.user.services.wireplumber.environment.ACP_PATHS_DIR = "/etc/alsa-card-profile/mixer/paths";
      systemd.user.services.wireplumber.environment.ACP_PROFILES_DIR = "/etc/alsa-card-profile/mixer/profile-sets";

      environment.etc."alsa-card-profile/mixer/profile-sets/9999-custom.conf".text = ''
        [Profile output:analog-stereo+output:hdmi-stereo+input:analog-stereo]
        description = Laptop + Display speakers
        output-mappings = analog-stereo hdmi-stereo
        input-mappings = analog-stereo
      '';

      environment.etc."alsa-card-profile/mixer/paths/analog-output-headphones.conf".source =
        "${pkgs.pipewire}/share/alsa-card-profile/mixer/paths/analog-output-headphones.conf";

      environment.etc."alsa-card-profile/mixer/paths/analog-output-speaker.conf".source =
        "${pkgs.pipewire}/share/alsa-card-profile/mixer/paths/analog-output-speaker.conf";

      environment.etc."alsa-card-profile/mixer/paths/analog-output.conf.common".source =
        pkgs.runCommand "analog-output.conf.common-no-iec958" {} ''
          sed \
            -e '/\[Element IEC958\]/,/^$/ s/switch = off/switch = ignore/' \
            -e '/\[Element IEC958 Optical Raw\]/,/^$/ s/switch = off/switch = ignore/' \
            ${pkgs.pipewire}/share/alsa-card-profile/mixer/paths/analog-output.conf.common \
            > $out
        '';

      services.pipewire.wireplumber.extraConfig.main = {
        # "wireplumber.settings" = {
        #   "device.restore-profile" = false;
        # };
        "monitor.alsa.rules" = [
          ({
            matches = [({
              "device.name" = "alsa_card.pci-0000_00_1f.3";
            })];
            actions.update-props."device.profile" = "output:analog-stereo+output:hdmi-stereo+input:analog-stereo";
            # actions.update-props."device.profile" = "output:hdmi-stereo+input:analog-stereo";
            # actions.update-props."api.alsa.soft-mixer" = true;
          })
          ({
            matches = [({
              "node.name" = "alsa_output.pci-0000_00_1f.3.hdmi-stereo";
            })];
            actions.update-props."node.description" = "Näyttö - Kaiuttimet (HDMI/DP)";
          })
          # ({
          #   matches = [({
          #     "node.name" = "alsa_output.pci-0000_00_1f.3.analog-stereo";
          #   })];
          #   actions.update-props."node.description" = "Läppäri - Kaiuttimet";
          # })
          # ({
          #   matches = [({
          #     "node.name" = "alsa_input.pci-0000_00_1f.3.analog-stereo";
          #   })];
          #   actions.update-props."node.description" = "Läppäri - Mikki";
          # })
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
    };
  };
}
