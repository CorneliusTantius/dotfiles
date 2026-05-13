#!/usr/bin/env bash
set -euo pipefail

GPU_PATH="/sys/class/drm/card1/device"

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
  echo 2 > "$GPU_PATH/pp_power_profile_mode"
  echo low > "$GPU_PATH/power_dpm_force_performance_level"

  echo "Applied AMDGPU low power settings"
  echo
  echo "power/control: $(cat "$GPU_PATH/power/control")"
  echo "power_dpm_force_performance_level: $(cat "$GPU_PATH/power_dpm_force_performance_level")"
  echo
  echo "pp_power_profile_mode:"
  grep 'POWER_SAVING' "$GPU_PATH/pp_power_profile_mode" || true
  echo
  echo "pp_dpm_sclk:"
  cat "$GPU_PATH/pp_dpm_sclk" || true
  echo
  echo "pp_dpm_mclk:"
  cat "$GPU_PATH/pp_dpm_mclk" || true
}

main "$@"
