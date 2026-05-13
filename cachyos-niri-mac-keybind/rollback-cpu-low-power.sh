#!/usr/bin/env bash
set -euo pipefail

CPU_SYS="/sys/devices/system/cpu"
PSTATE_SYS="$CPU_SYS/intel_pstate"
SERVICE_NAME="cpu-low-power.service"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"

need_root() {
  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    exec sudo "$0" "$@"
  fi
}

set_if_writable() {
  local value="$1"
  local path="$2"
  [[ -w "$path" ]] || return 0
  echo "$value" > "$path"
}

main() {
  need_root "$@"

  for f in "$CPU_SYS"/cpu*/cpufreq/scaling_governor; do
    [[ -e "$f" ]] || continue
    echo powersave > "$f"
  done

  for f in "$CPU_SYS"/cpu*/cpufreq/energy_performance_preference; do
    [[ -e "$f" ]] || continue
    echo balance_performance > "$f"
  done

  set_if_writable 0 "$PSTATE_SYS/no_turbo"
  set_if_writable 1 "$PSTATE_SYS/hwp_dynamic_boost"
  set_if_writable 16 "$PSTATE_SYS/min_perf_pct"
  set_if_writable 100 "$PSTATE_SYS/max_perf_pct"

  if systemctl list-unit-files "$SERVICE_NAME" >/dev/null 2>&1; then
    systemctl disable --now "$SERVICE_NAME" || true
  fi

  if [[ -f "$SERVICE_PATH" ]]; then
    rm -f "$SERVICE_PATH"
    systemctl daemon-reload
  fi

  echo "Rolled back CPU low-power settings"
  echo
  for f in \
    "$CPU_SYS/cpu0/cpufreq/scaling_governor" \
    "$CPU_SYS/cpu0/cpufreq/energy_performance_preference" \
    "$PSTATE_SYS/no_turbo" \
    "$PSTATE_SYS/hwp_dynamic_boost" \
    "$PSTATE_SYS/min_perf_pct" \
    "$PSTATE_SYS/max_perf_pct"; do
    [[ -r "$f" ]] && echo "$f: $(cat "$f")"
  done
}

main "$@"
