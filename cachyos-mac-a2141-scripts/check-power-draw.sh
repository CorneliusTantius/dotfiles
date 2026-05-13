#!/usr/bin/env bash
set -euo pipefail

BAT_PATH="/sys/class/power_supply/BAT0"

[[ -d "$BAT_PATH" ]] || {
  echo "Battery path not found: $BAT_PATH" >&2
  exit 1
}

cleanup() {
  stty sane 2>/dev/null || true
}
trap cleanup EXIT INT TERM

if [[ -t 0 ]]; then
  stty -echo -icanon time 0 min 0
fi

while true; do
  status="$(<"$BAT_PATH/status")"
  current="$(<"$BAT_PATH/current_now")"
  voltage="$(<"$BAT_PATH/voltage_now")"
  capacity="$(<"$BAT_PATH/capacity")"

  clear
  python - <<PY
status = ${status@Q}
current_ua = int(${current@Q})
voltage_uv = int(${voltage@Q})
capacity = int(${capacity@Q})
current_a = current_ua / 1e6
voltage_v = voltage_uv / 1e6
power = current_a * voltage_v
print(f"Status: {status}")
print(f"Capacity: {capacity}%")
print(f"Current: {current_a:.3f} A")
print(f"Voltage: {voltage_v:.3f} V")
print(f"Power: {power:.2f} W")
print()
print("Press q to quit")
PY

  if read -r -n 1 key; then
    [[ "$key" == "q" ]] && break
  fi

  sleep 1
done
