#!/usr/bin/env bash
set -euo pipefail

SERVICE_PATH="/etc/systemd/system/cpu-low-power.service"
SCRIPT_PATH="/home/nelly/workspace/cachyos-mac-a2141-scripts/set-cpu-medium-low.sh"

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  exec sudo "$0" "$@"
fi

[[ -x "$SCRIPT_PATH" ]] || {
  echo "Missing executable: $SCRIPT_PATH" >&2
  exit 1
}

cat > "$SERVICE_PATH" <<EOF
[Unit]
Description=Apply CPU medium-low power settings
After=multi-user.target
ConditionPathExists=/sys/devices/system/cpu/intel_pstate/max_perf_pct

[Service]
Type=oneshot
ExecStart=$SCRIPT_PATH
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now cpu-low-power.service

echo "Installed and started cpu-low-power.service (medium-low profile)"
systemctl --no-pager --full status cpu-low-power.service || true
