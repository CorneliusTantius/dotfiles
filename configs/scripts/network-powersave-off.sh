#!/usr/bin/env bash

if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run this script with sudo or as root." >&2
  exit 1
fi

NM_CONF_DIR="/etc/NetworkManager/conf.d"
NM_CONF_FILE="$NM_CONF_DIR/wifi-powersave-off.conf"

mkdir -p "$NM_CONF_DIR"

cat << 'EOF' > "$NM_CONF_FILE"
[connection]
wifi.powersave = 2
EOF

systemctl restart NetworkManager

if command -v iw &> /dev/null; then
  # Loop through all wireless interfaces and turn off power save
  for interface in /sys/class/net/*; do
    if [ -d "$interface/wireless" ] || [ -d "$interface/phy80211" ]; then
      ifname=$(basename "$interface")
      iw dev "$ifname" set power_save off || true
    fi
  done
fi
