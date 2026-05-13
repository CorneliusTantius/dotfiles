#!/usr/bin/env bash
set -euo pipefail

MAX_PERF_PCT="${MAX_PERF_PCT:-75}"
MIN_PERF_PCT="${MIN_PERF_PCT:-16}"
EPP="${EPP:-balance_power}"
CPU_SYS="/sys/devices/system/cpu"
PSTATE_SYS="$CPU_SYS/intel_pstate"

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
    echo "$EPP" > "$f"
  done

  set_if_writable 1 "$PSTATE_SYS/no_turbo"
  set_if_writable 0 "$PSTATE_SYS/hwp_dynamic_boost"
  set_if_writable "$MIN_PERF_PCT" "$PSTATE_SYS/min_perf_pct"
  set_if_writable "$MAX_PERF_PCT" "$PSTATE_SYS/max_perf_pct"

  echo "Applied CPU medium-low power settings"
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
