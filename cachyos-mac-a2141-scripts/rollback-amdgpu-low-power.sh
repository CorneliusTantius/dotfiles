#!/usr/bin/env bash
set -euo pipefail

GPU_PATH="/sys/class/drm/card1/device"
SERVICE_NAME="amdgpu-low-power.service"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"

need_root() {
  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    exec sudo "$0" "$@"
  fi
}

main() {
  need_root "$@"

  [[ -d "$GPU_PATH" ]] || {
    echo "Missing GPU path: $GPU_PATH" >&2
    exit 1
  }

  echo auto > "$GPU_PATH/power/control"
  echo 0 > "$GPU_PATH/pp_power_profile_mode"
  echo auto > "$GPU_PATH/power_dpm_force_performance_level"

  if systemctl list-unit-files "$SERVICE_NAME" >/dev/null 2>&1; then
    systemctl disable --now "$SERVICE_NAME" || true
  fi

  if [[ -f "$SERVICE_PATH" ]]; then
    rm -f "$SERVICE_PATH"
    systemctl daemon-reload
  fi

  echo "Rolled back AMDGPU low-power settings"
  echo
  echo "power/control: $(cat "$GPU_PATH/power/control")"
  echo "power_dpm_force_performance_level: $(cat "$GPU_PATH/power_dpm_force_performance_level")"
  echo
  echo "pp_power_profile_mode:"
  sed -n '1,12p' "$GPU_PATH/pp_power_profile_mode" || true
}

main "$@"
