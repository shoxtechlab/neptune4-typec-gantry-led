# Neptune 4 Plus Type-C: persistent gantry LED control

Control the upper gantry LED of an **ELEGOO Neptune 4 Plus Type-C** from Fluidd or Mobileraker.

On the tested Type-C firmware, the commonly documented `gpio66`-only method produces only a brief flash. Observing the stock touchscreen revealed that its upper-light operation drives both Linux GPIO lines and both Makerbase command files together.

> [日本語版はこちら](README.ja.md)

## Tested configuration

- Printer: ELEGOO Neptune 4 Plus, Type-C toolhead cable version
- Main firmware: `V1.4.1.4`
- Touchscreen firmware: `1.2.22`
- Klipper frontend: Fluidd / Mobileraker
- Date tested: 2026-11-09

This has **not** been tested on the older ribbon-cable version, Neptune 4/4 Pro, or Neptune 4 Max.

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

## License

The original files in this repository are released under the MIT License. KIAUH and its `gcode_shell_command.py` extension are separate upstream software under their own license.
