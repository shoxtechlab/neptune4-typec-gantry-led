#!/bin/sh
set -eu

gantry_state=$(cat /home/mks/gpio66_value)

case "$gantry_state" in
  2)
    # Request ON through both Makerbase control files.
    printf '1\n' > /home/mks/gpio79_value
    printf '1\n' > /home/mks/gpio66_value
    ;;
  3)
    # Request OFF through both Makerbase control files.
    printf '0\n' > /home/mks/gpio66_value
    printf '0\n' > /home/mks/gpio79_value
    ;;
  *)
    echo "Unexpected gantry light state: $gantry_state" >&2
    exit 1
    ;;
esac
