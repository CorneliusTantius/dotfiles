#!/usr/bin/env bash
set -euo pipefail

SERVICE_PATH="/etc/systemd/system/amdgpu-low-power.service"
SCRIPT_PATH="/home/nelly/workspace/set-amdgpu-low-power.sh"

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  exec sudo "$0" "$@"
fi

[[ -x "$SCRIPT_PATH" ]] || {
  echo "Missing executable: $SCRIPT_PATH" >&2
  exit 1
}

cat > "$SERVICE_PATH" <<EOF
[Unit]
Description=Apply AMDGPU low-power settings
After=multi-user.target
ConditionPathExists=/sys/class/drm/card1/device/power_dpm_force_performance_level

[Service]
Type=oneshot
ExecStart=$SCRIPT_PATH
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now amdgpu-low-power.service

echo "Installed and started amdgpu-low-power.service"
systemctl --no-pager --full status amdgpu-low-power.service || true
