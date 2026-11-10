# Neptune 4 Plus Type-C: persistent gantry LED control

Control the upper gantry LED of an **ELEGOO Neptune 4 Plus Type-C** from Fluidd or Mobileraker.

This repository does not claim the dual-command-file technique as a new invention. Similar methods were previously shared for the Neptune 4 Pro and Max. This is a reproducible test and adaptation for a current Neptune 4 Plus Type-C, including behavior not documented in those earlier guides.

> [日本語版はこちら](README.ja.md)

## Tested configuration

- Printer: ELEGOO Neptune 4 Plus, Type-C toolhead cable version
- Main firmware: `V1.4.1.4`
- Touchscreen firmware: `1.2.22`
- Klipper frontend: Fluidd / Mobileraker
- Date tested: 2026-11-09

Additional test: main firmware `V1.4.1.5` (2026-11-10)

This has **not** been tested on the older ribbon-cable version, Neptune 4/4 Pro, or Neptune 4 Max.

## After updating to V1.4.1.5

After updating the same printer from `V1.4.1.4` to `V1.4.1.5`, running `FLASHLIGHT_SWITCH` from Fluidd no longer switched the light and returned:

```text
Unknown command:"RUN_SHELL_COMMAND"
```

The following was verified on the updated printer:

- the `FLASHLIGHT_SWITCH` and `MODLELIGHT_SWITCH` macros remained in `printer.cfg`;
- `/home/mks/klipper/klippy/extras/gcode_shell_command.py` also remained installed;
- however, the `[gcode_shell_command FLASHLIGHT]` and `[gcode_shell_command MODLELIGHT]` sections referenced by those macros were gone;
- after recovery, the GPIO acknowledgement states remained `3 / 3 = ON` and `2 / 2 = OFF`, matching `V1.4.1.4`.

In this specific state, Klipper and the extension do not need to be reinstalled. Restore the missing definitions in `printer.cfg` **before the auto-generated save block**:

```ini
[gcode_shell_command FLASHLIGHT]
command: sh /home/mks/sled2.sh
timeout: 5.
verbose: True

[gcode_shell_command MODLELIGHT]
command: sh /home/mks/sled1.sh
timeout: 5.
verbose: True
```

> [!CAUTION]
> Place these sections before `#*# <---------------------- SAVE_CONFIG ---------------------->`. Appending normal configuration after that block can prevent saved PID values and bed meshes from loading, resulting in a Klipper startup error or a missing mesh profile.

Back up `printer.cfg` before editing it. After restarting Klipper, confirm that its state is `ready` and that the required bed mesh still exists. Then run `FLASHLIGHT_SWITCH` twice to verify both ON and OFF operation.

## Prior art and scope of this test

Earlier community work established the important foundations:

- A [March 2024 German forum post](https://forum.drucktipps3d.de/forum/thread/30746-elegoo-neptune-4-pro-lichter-direkt-beim-starten-aktivieren/?pageNo=2) switches both `/home/mks/gpio66_value` and `/home/mks/gpio79_value` for a Neptune 4 Pro.
- The [`Tsoukan/MyElegooN4Max`](https://github.com/Tsoukan/MyElegooN4Max) repository contains related light-control scripts for a Neptune 4 Max.
- A [2026 Type-C discussion](https://www.reddit.com/r/ElegooNeptune4/comments/1ue955n/neptune_4_max_observation_light_control/) documents the missing `gcode_shell_command.py` problem and the KIAUH extension fix on recent hardware.

This repository adds a tested Neptune 4 Plus Type-C combination and records the following observations:

- exact main/UI firmware versions;
- the brief-flash failure when only GPIO 66 is driven;
- touchscreen-observed simultaneous GPIO 66/79 transitions;
- the Makerbase acknowledgement states `2` (off) and `3` (on);
- a single toggle script tested through Fluidd and Mobileraker.

## What was observed

The stock touchscreen was monitored while switching the upper light on and off:

| Operation | `/home/mks/gpio66_value` | `/home/mks/gpio79_value` | GPIO 66 | GPIO 79 |
|---|---:|---:|---:|---:|
| Off | `2` | `2` | `0` | `0` |
| On | `3` | `3` | `1` | `1` |

Writing to GPIO 66 alone caused a short flash and immediately returned low. Sending the ON/OFF request through **both** Makerbase command files reproduced the touchscreen behavior and held the state.

The command-file protocol observed on this machine was:

- write `1` to request ON; the stock service acknowledges it as `3`
- write `0` to request OFF; the stock service acknowledges it as `2`

## Installation

### 1. Back up the stock script and config

```sh
cp -p /home/mks/sled2.sh /home/mks/sled2.sh.backup
cp -p ~/printer_data/config/printer.cfg ~/printer_data/config/printer.cfg.backup
```

### 2. Install the corrected script

Copy [`scripts/sled2.sh`](scripts/sled2.sh) to `/home/mks/sled2.sh`, then run:

```sh
chmod 755 /home/mks/sled2.sh
```

### 3. Restore `RUN_SHELL_COMMAND` if it is missing

Some Type-C firmware images do not include Klipper's `gcode_shell_command.py`, even though the stock macros refer to it. Install the extension using the upstream KIAUH extension installer, or obtain it from the [KIAUH source](https://github.com/dw-0/kiauh/tree/master/kiauh/extensions/gcode_shell_cmd).

Do not replace the printer's complete Klipper installation just to add this extension.

### 4. Add the Klipper configuration

Add the contents of [`config/gantry-led.cfg`](config/gantry-led.cfg) to `printer.cfg`, unless equivalent sections already exist. Restart Klipper and confirm its state is `ready`.

Run this macro from Fluidd or Mobileraker:

```gcode
GANTRY_LED_TOGGLE
```

The stock name `FLASHLIGHT_SWITCH` can be kept instead if preferred.

## Recovery

If Klipper reports a configuration error, restore the backup:

```sh
cp -p ~/printer_data/config/printer.cfg.backup ~/printer_data/config/printer.cfg
cp -p /home/mks/sled2.sh.backup /home/mks/sled2.sh
```

Then restart Klipper. This procedure does not flash the mainboard MCU or touchscreen firmware.

## Notes

- Treat shell-command macros as privileged functionality. Only configure fixed commands; do not pass arbitrary user input to a shell.
- Firmware updates may overwrite `/home/mks/sled2.sh` or change the command-file protocol.
- GPIO assignments and behavior may differ on other hardware revisions.
- Credit for the dual-file control concept belongs to the earlier community work linked above. This repository is a Type-C Plus validation and adaptation.

## License

The original files in this repository are released under the MIT License. KIAUH and its `gcode_shell_command.py` extension are separate upstream software under their own license.
