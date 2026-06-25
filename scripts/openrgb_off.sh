#!/usr/bin/env sh
set -eu

if ! command -v openrgb >/dev/null 2>&1; then
  if command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --needed openrgb
  else
    exit 0
  fi
fi

turn_off_rgb() {
  device_ids=$(openrgb --list-devices 2>/dev/null | awk -F: '/^[0-9]+:/ {print $1}')
  [ -n "${device_ids:-}" ] || return 1

  changed=0
  for device_id in $device_ids; do
    if openrgb --device "$device_id" --mode off >/dev/null 2>&1 || \
       openrgb --device "$device_id" --mode direct --color 000000 >/dev/null 2>&1 || \
       openrgb --device "$device_id" --mode static --color 000000 >/dev/null 2>&1; then
      changed=1
    fi
  done

  [ "$changed" -eq 1 ]
}

# ponytail: simple retry loop so boot races do not leave RGB on; add device-specific handling only if this misses hardware
attempt=0
while [ "$attempt" -lt 10 ]; do
  if turn_off_rgb; then
    exit 0
  fi

  attempt=$((attempt + 1))
  sleep 2
done

exit 1
