#!/usr/bin/env sh
set -eu

echo '==> openrgb setup'
command -v pacman >/dev/null 2>&1 || exit 0

echo '==> install openrgb'
pacman -S --needed --noconfirm openrgb

echo '==> write rgb-off runner'
install -d /usr/local/bin
cat <<'EOF' > /usr/local/bin/openrgb_force_off.sh
#!/usr/bin/env sh
set -eu

echo '==> openrgb force off'
command -v openrgb >/dev/null 2>&1 || exit 0

turn_off_rgb() {
  device_ids=$(openrgb --list-devices 2>/dev/null | awk -F: '/^[0-9]+:/ {print $1}')
  [ -n "${device_ids:-}" ] || return 1

  changed=0
  for device_id in $device_ids; do
    echo "==> try device $device_id"
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
  echo "==> rgb off attempt $((attempt + 1))/10"
  if turn_off_rgb; then
    echo '==> rgb off done'
    exit 0
  fi

  attempt=$((attempt + 1))
  sleep 2
done

echo '==> rgb off failed'
exit 1
EOF
chmod 755 /usr/local/bin/openrgb_force_off.sh

echo '==> openrgb runner ready: /usr/local/bin/openrgb_force_off.sh'
