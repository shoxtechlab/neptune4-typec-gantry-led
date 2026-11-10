#!/bin/sh
set -eu

gantry_state=$(cat /home/mks/gpio79_value)

case "$gantry_state" in
  2)
    # GPIO 79 is the effective control input on the tested Type-C revision.
    printf '1\n' > /home/mks/gpio79_value
    ;;
  3)
    # GPIO 79 drives both physical GPIO outputs on this revision.
    printf '0\n' > /home/mks/gpio79_value
    ;;
  *)
    echo "Unexpected gantry light state: $gantry_state" >&2
    exit 1
    ;;
esac
