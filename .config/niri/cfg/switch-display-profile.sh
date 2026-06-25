#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
NIRI_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
DISPLAY_CFG="$SCRIPT_DIR/display.kdl"

usage() {
    cat <<'EOF'
Usage: switch-display-profile.sh

Launches an interactive menu:
  1) lenovo   Lenovo L32p-30 on DP-3
  2) skydata  SKYDATA H27G30Q on DP-3
  3) status   Show active profile
EOF
}

active_profile() {
    if grep -q 'include "./displays/lenovo-l32p-30.kdl"' "$DISPLAY_CFG"; then
        echo "lenovo"
    elif grep -q 'include "./displays/skydata-h27g30q.kdl"' "$DISPLAY_CFG"; then
        echo "skydata"
    else
        echo "unknown"
    fi
}

choose_profile() {
    {
        echo "active: $(active_profile)"
        echo
        echo "Choose display profile:"
        echo "  1) lenovo  - Lenovo L32p-30 on DP-3"
        echo "  2) skydata - SKYDATA H27G30Q on DP-3"
        echo "  3) status  - show active profile"
        echo "  q) quit"
        echo
        printf "Selection: "
    } >&2
    read -r choice

    case "$choice" in
        1|l|L|lenovo|Lenovo)
            echo "lenovo"
            ;;
        2|s|S|skydata|Skydata|SKYDATA)
            echo "skydata"
            ;;
        3|status|Status)
            echo "status"
            ;;
        q|Q|quit|Quit|exit|Exit)
            echo "quit"
            ;;
        -h|--help|help|Help)
            echo "help"
            ;;
        *)
            echo "invalid"
            ;;
    esac
}

profile="$(choose_profile)"
case "$profile" in
    lenovo)
        include='include "./displays/lenovo-l32p-30.kdl"'
        commented='// include "./displays/skydata-h27g30q.kdl"'
        ;;
    skydata)
        include='include "./displays/skydata-h27g30q.kdl"'
        commented='// include "./displays/lenovo-l32p-30.kdl"'
        ;;
    status)
        echo "active: $(active_profile)"
        exit 0
        ;;
    quit)
        exit 0
        ;;
    help)
        usage
        exit 0
        ;;
    invalid)
        echo "invalid selection" >&2
        exit 2
        ;;
esac

backup="$DISPLAY_CFG.bak-$(date +%Y%m%d%H%M%S)"
cp "$DISPLAY_CFG" "$backup"

tmp="$(mktemp "$DISPLAY_CFG.tmp.XXXXXX")"
cat > "$tmp" <<EOF
// ────────────── Output Configuration ──────────────
// Run \`niri msg outputs\` to get correct names.
// Docs: https://github.com/YaLTeR/niri/wiki/Configuration:-Outputs
//
// Manual profiles live in ./displays/.
// Switch with: ./cfg/switch-display-profile.sh

$include
$commented
EOF
mv "$tmp" "$DISPLAY_CFG"

if ! niri validate -c "$NIRI_DIR/config.kdl"; then
    cp "$backup" "$DISPLAY_CFG"
    echo "validation failed; restored $backup" >&2
    exit 1
fi

if niri msg action load-config; then
    echo "active: $profile"
else
    echo "config updated + valid, but reload failed" >&2
    echo "manual reload: niri msg action load-config" >&2
    exit 1
fi
