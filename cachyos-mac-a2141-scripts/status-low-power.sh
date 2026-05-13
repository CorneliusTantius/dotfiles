#!/usr/bin/env bash
set -euo pipefail

CPU_SYS="/sys/devices/system/cpu"
PSTATE_SYS="$CPU_SYS/intel_pstate"
GPU_PATH="/sys/class/drm/card1/device"

show_file() {
  local label="$1"
  local path="$2"
  if [[ -r "$path" ]]; then
    printf '%-42s %s\n' "$label:" "$(cat "$path")"
  else
    printf '%-42s %s\n' "$label:" "n/a"
  fi
}

echo '== CPU =='
show_file 'scaling_governor (cpu0)' "$CPU_SYS/cpu0/cpufreq/scaling_governor"
show_file 'energy_performance_preference (cpu0)' "$CPU_SYS/cpu0/cpufreq/energy_performance_preference"
show_file 'intel_pstate status' "$PSTATE_SYS/status"
show_file 'no_turbo' "$PSTATE_SYS/no_turbo"
show_file 'hwp_dynamic_boost' "$PSTATE_SYS/hwp_dynamic_boost"
show_file 'min_perf_pct' "$PSTATE_SYS/min_perf_pct"
show_file 'max_perf_pct' "$PSTATE_SYS/max_perf_pct"

echo
echo '== AMDGPU =='
show_file 'power/control' "$GPU_PATH/power/control"
show_file 'power_dpm_force_performance_level' "$GPU_PATH/power_dpm_force_performance_level"

echo 'pp_power_profile_mode:'
if [[ -r "$GPU_PATH/pp_power_profile_mode" ]]; then
  grep -E '^( 2   POWER_SAVING\*| 0 BOOTUP_DEFAULT\*| 1 3D_FULL_SCREEN\*| 3   VIDEO\*| 4             VR\*| 5        COMPUTE\*| 6         CUSTOM\*)' "$GPU_PATH/pp_power_profile_mode" || sed -n '1,12p' "$GPU_PATH/pp_power_profile_mode"
else
  echo 'n/a'
fi

echo
echo 'pp_dpm_sclk:'
[[ -r "$GPU_PATH/pp_dpm_sclk" ]] && cat "$GPU_PATH/pp_dpm_sclk" || echo 'n/a'

echo
echo 'pp_dpm_mclk:'
[[ -r "$GPU_PATH/pp_dpm_mclk" ]] && cat "$GPU_PATH/pp_dpm_mclk" || echo 'n/a'

echo
echo '== Services =='
for s in cpu-low-power.service amdgpu-low-power.service power-profiles-daemon.service tlp.service; do
  enabled=$(systemctl is-enabled "$s" 2>/dev/null || true)
  active=$(systemctl is-active "$s" 2>/dev/null || true)
  printf '%-30s enabled=%-12s active=%s\n' "$s" "${enabled:-n/a}" "${active:-n/a}"
done
