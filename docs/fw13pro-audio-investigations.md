# Framework 13 Pro audio investigations

## Goal and setup

On this machine, `alsa_card.pci-0000_00_1f.3` (HDA Intel PCH, Realtek ALC285 analog codec and Intel HDMI/DP codec) provides the laptop speakers / 3.5 mm headphone jack and the external display speakers. Audio is managed by PipeWire and WirePlumber; the NixOS configuration is in [`modules/aspects/fw13pro-audio.nix`](../modules/aspects/fw13pro-audio.nix).

The standard ACP profiles `output:analog-stereo+input:analog-stereo` and `output:hdmi-stereo+input:analog-stereo` each expose only one output. The goal is to expose **both analog and HDMI sinks simultaneously**, retaining the analog microphone, while allowing the analog sink to switch between laptop speakers and headphones. This is not a request to mirror the same audio to both outputs: separate sinks suffice.

## Loading a combined ACP profile

PipeWire's built-in profile set is at `/run/current-system/sw/share/alsa-card-profile/mixer/profile-sets/default.conf` (in the Nix store), not `/usr/share/...`. It ends with `.include 9999-custom.conf`. An ACP profile can name multiple space-separated output mappings, creating a separate sink for each.

The initial custom profile was:

```ini
[Profile output:analog-stereo+output:hdmi-stereo+input:analog-stereo]
description = Laptop + Display speakers
output-mappings = analog-stereo hdmi-stereo
input-mappings = analog-stereo
```

Two setup mistakes initially prevented it from taking effect:

- Putting `9999-custom.conf` under `/etc/alsa-card-profile/mixer/profile-sets/` alone did not affect the Nix-store `default.conf`, which includes the *other* `9999-custom.conf` alongside itself. The configuration now installs `default.conf` under `/etc/alsa-card-profile/mixer/profile-sets/` as well and sets `systemd.user.services.wireplumber.environment.ACP_PROFILES_DIR` to that directory.
- The WirePlumber device rule must set **`device.profile`**, not `profile`. The wrong property showed up in `wpctl inspect` but was ignored by WirePlumber's profile-selection policy. The rule now matches `alsa_card.pci-0000_00_1f.3` and sets `device.profile` to the combined profile name. The old custom Lua profile-selection script in the module is commented out.

After these changes, `wpctl status` showed separate analog and HDMI sinks and an analog source. A useful check after changes is `pw-cli enum-params <card-device-id> EnumProfile` to verify the custom profile actually exists. Device IDs are transient; look up the current ID with `wpctl status`.

## HDMI stops on analog jack changes with the full ACP paths

When the combined profile uses **the standard `analog-stereo` output mapping**, plugging **or** unplugging the 3.5 mm jack during continuous HDMI playback causes the display to go silent. KDE still selects and shows audio activity on HDMI. WirePlumber logs show the combined profile remains selected; it switches `analog-output-speaker` ↔ `analog-output-headphones` and keeps Firefox linked to HDMI. `pw-top` likewise showed Firefox and the HDMI sink running. Waiting until playback stops long enough for idle suspension, then starting playback again, restores HDMI audio. One experiment found that `pactl suspend-sink alsa_output.pci-0000_00_1f.3.hdmi-stereo 1` also caused sound to return; **`1` requests suspension**, so this is an observed recovery behavior, not an explanation of how it works.

Tests performed:

| Test | Result |
| --- | --- |
| Disable Easy Effects; connect Firefox directly to HDMI | Still reproduces. Not caused by Easy Effects. |
| Set `api.alsa.soft-mixer = true` in the card's WirePlumber rule | Did not fix HDMI. This change was subsequently commented out; it also coincided with loss of headphone sound until reboot. |
| Temporarily set `/sys/module/snd_hda_intel/parameters/power_save` to `0` and `power_save_controller` to `N` | Did not fix HDMI. Values were changed back to `10` and `Y`; reboot restored headphone sound after these experiments. |
| Select the existing HDMI-only profile | Jack changes did **not** interrupt HDMI. |
| Select `pro-audio`, route to the display via its port 3 | Jack changes did **not** interrupt HDMI. This mode does not supply the normal ACP analog ports. Returned to the combined profile afterwards. |
| In the combined profile, replace the analog output mapping with a mapping without `paths-output` | HDMI **continues playing** across jack changes. |
| While using that raw mapping, toggle the ALSA `Headphone` and `Speaker` switches and `Auto-Mute Mode` with `amixer` | Neither test alone interrupted HDMI. Those controls were not the cause. |
| Return to the standard analog mapping, compare `amixer -c PCH` before/after an HDMI-silencing jack change | `IEC958,0` became muted. `amixer -c PCH sset IEC958 unmute` immediately restored HDMI sound. |

**Cause identified:** `/run/current-system/sw/share/alsa-card-profile/mixer/paths/analog-output.conf.common` includes `[Element IEC958]` with `switch = off` (and likewise `[Element IEC958 Optical Raw]`). Both standard `analog-output-speaker.conf` and `analog-output-headphones.conf` include that common file. When ACP activates one of those analog paths on a jack event, it mutes the `IEC958,0` hardware control needed for this card's simultaneously active HDMI output. Unmuting that control restores sound without changing PipeWire routing. HDMI-only, Pro Audio and the raw analog mapping avoid the problematic analog path activation. The behavior on playback pause/resume is consistent with the HDMI sink reopening and unmuting the control; that particular step has not been independently confirmed.

## Working fix: preserve IEC958 during analog port changes

The configuration in `modules/aspects/fw13pro-audio.nix` now keeps the original combined profile with `output-mappings = analog-stereo hdmi-stereo` and the normal analog speaker/headphone paths. It installs unmodified copies of `analog-output-speaker.conf` and `analog-output-headphones.conf` under `/etc/alsa-card-profile/mixer/paths/`, and generates a local `analog-output.conf.common` there with `switch = ignore` instead of `switch = off` for `[Element IEC958]`. Their relative `.include analog-output.conf.common` then reads the modified common file placed beside them, while other path files still fall back to the PipeWire package's built-in paths.

Setting `[Element IEC958 Optical Raw]` to `switch = ignore` was tested and later removed without any change in behavior; this card apparently has no such mixer element, so ACP presumably skips that stanza. Only the plain `IEC958` element is relevant on this hardware. `ACP_PATHS_DIR` and `ACP_PROFILES_DIR` were set on the WirePlumber user service and later removed, also without any change in behavior. ACP's `get_data_path()` (`spa/plugins/alsa/acp/compat.c` in the PipeWire source) checks those environment variables only as one option; it additionally always checks `/etc/alsa-card-profile/mixer/<paths|profile-sets>` as a built-in fallback location (before falling back further to the Nix store's bundled files), which is exactly where these files are installed. So the env vars are unnecessary for files placed at that fixed `/etc` path; they would only matter for a custom location outside of it.

**After this change, HDMI stays audible when headphones are plugged/unplugged**, and no regression with other audio devices has been noticed so far. This preserves normal speaker/headphone port selection instead of relying on the raw mapping. Further testing after reboots and with varied audio devices would still be useful.

## Earlier workaround: analog output without ACP mixer paths

The following raw-mapping version of `fw13pro-audio.nix` was tested (it has since been reverted to the normal analog mapping):

```ini
[Mapping analog-stereo-raw]
device-strings = front:%f
channel-map = left,right
direction = output

[Profile output:analog-stereo+output:hdmi-stereo+input:analog-stereo]
description = Laptop + Display speakers (test)
output-mappings = analog-stereo-raw hdmi-stereo
input-mappings = analog-stereo
```

The profile name remains the same, so the WirePlumber `device.profile` rule still selects it. This exposes both output sinks and the analog input without the default analog speaker/headphone ACP paths; HDMI stays audible during jack changes.

To switch speaker/headphone output without ACP paths, setting ALSA's `Auto-Mute Mode` to `Enabled` was tested and appeared to work. It was `Disabled` before this experiment. This mixer setting was applied interactively, **not** declared in the NixOS module. The raw mapping also does not initialize or restore a useful headphone hardware volume: the `Headphone` mixer control was observed at 0% / off. Increasing it to 60% with `amixer` made headphones louder. With `Headphone` **unmuted** at 60%, playback stayed audible after idle pause/resume and after unplug/replug. At 0%, output was very quiet; explicitly setting the control to **mute** produced very quiet output on plug-in and silence after idle playback. The proposed analog `session.suspend-timeout-seconds = 0` experiment was **not** run: these tests point instead to the hardware headphone mixer switch/level.

The remaining limitation is that `analog-stereo-raw` is **one sink with one KDE volume slider** for both speakers and headphones; it has no separate ACP routes with independently remembered volumes. `Headphone` and `Speaker` are separate ALSA hardware controls, so lowering `Headphone` to a safe level while leaving `Speaker` higher gives different *effective* levels under the shared KDE slider. This is a safety limit, not separate per-port KDE volume memory; software amplification above 100% could defeat the limit. The hardware headphone level / `Auto-Mute Mode` were not declaratively set or confirmed persistent across reboots in this workaround.

## Remaining checks

- Verify that HDMI playback and speaker/headphone port switching still work after a cold boot and suspend/resume, and that speaker/headphone volume settings behave as expected. Other devices have shown no noticed regression so far.
- The override for the common analog path applies to any analog speaker/headphone path that includes it while this WirePlumber service uses `ACP_PATHS_DIR`. If another device needs the original `IEC958`-muting behavior, consider device-specific paths and a dedicated analog mapping instead of the shared override.
- The `pactl suspend-sink ... 1` recovery and the proposed analog suspension-timeout change were workarounds/experiments, not fixes for this issue.
