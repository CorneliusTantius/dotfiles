#!/bin/sh
# Configure the laptop panel and the external monitor from one menu.
#
# Usage:
#   sh monitor-layout.sh                 pick an action from a menu
#   sh monitor-layout.sh layout          move the external monitor (top/left/right/bottom)
#   sh monitor-layout.sh mode            pick resolution + refresh rate
#   sh monitor-layout.sh toggle-main     enable/disable the laptop panel
#   sh monitor-layout.sh toggle-ext      enable/disable the external monitor
#   add --dry-run to print the config instead of applying it
#
# Writes ~/.config/mango/monitor.conf (loaded by config.conf through
# source_optional) and reloads mango.
#
# mango rejects a monitor_rule that sets width without height and refresh, so a
# mode is always written as the whole width,height,refresh trio.

set -eu

CONF="$HOME/.config/mango/monitor.conf"
action=""
choice=""
dry=0
for arg in "$@"; do
    case $arg in
        --dry-run) dry=1 ;;
        layout|mode|toggle-main|toggle-ext) action=$arg ;;
        *) choice=$arg ;;
    esac
done

pick() {
    # Pick from stdin; prints nothing when cancelled.
    fuzzel --dmenu --prompt "$1: " --minimal-lines --lines=12 || true
}

# Rewrite monitor.conf: ensure a rule exists for each name, then override fields.
# argv: name=value pairs, e.g. eDP-1=width:1920,height:1200,refresh:60,x:0,y:0
edit_conf() {
    python3 - "$CONF" "$@" <<'EOF'
import re, sys
conf, *specs = sys.argv[1:]
try:
    lines = [l for l in open(conf).read().splitlines() if l.startswith("monitor_rule=")]
except OSError:
    lines = []
rules = []  # [(name_regex, {field: value})]
for line in lines:
    kv = dict(f.split(":", 1) for f in line[len("monitor_rule="):].split(",") if ":" in f)
    rules.append([kv.pop("name", ""), kv])

for spec in specs:
    name, fields = spec.split("=", 1)
    new = dict(f.split(":", 1) for f in fields.split(",") if ":" in f)
    for rule in rules:
        if re.fullmatch(rule[0], name):
            rule[1].update(new)
            break
    else:
        rules.append([f"^{name}$", new])

for name, kv in rules:
    print("monitor_rule=" + ",".join([f"name:{name}"] + [f"{k}:{v}" for k, v in kv.items()]))
EOF
}

apply_conf() {
    if [ "$dry" -eq 1 ]; then
        printf '%s\n' "$1"
        return 0
    fi
    mkdir -p "$(dirname "$CONF")"
    printf '%s\n' "$1" > "$CONF"
    mmsg dispatch reload_config >/dev/null
    echo "Updated $CONF."
}

# Output state as JSON; empty when wlr-randr is not installed.
randr_json() {
    wlr-randr --json 2>/dev/null
}

# Current logical size of a monitor.
dims() {
    randr_json | python3 -c '
import json, sys
for h in json.load(sys.stdin):
    if h["name"] == sys.argv[1]:
        cur = next((m for m in h.get("modes", []) if m.get("current")), None)
        print(cur["width"], cur["height"]) if cur else print(1920, 1080)
        break
else:
    print(1920, 1080)
' "$1"
}

# Detected monitors: built-in panel and first external output.
if randr_json >/dev/null 2>&1; then
    names=$(randr_json | python3 -c '
import json, sys
for h in json.load(sys.stdin):
    if h.get("enabled", True):
        print(h["name"])
')
else
    names=""
    for c in /sys/class/drm/card*-*; do
        [ -e "$c/status" ] || continue
        [ "$(cat "$c/status")" = connected ] || continue
        n=$(basename "$c")
        names="$names ${n#card*-}"
    done
fi

main=""
ext=""
for n in $names; do
    case $n in
        eDP*|LVDS*|DSI*) [ -z "$main" ] && main=$n ;;
        *) [ -z "$ext" ] && ext=$n ;;
    esac
done
[ -n "$main" ] || main=$ext

if [ -z "$action" ]; then
    action=$(printf 'layout\nmode\ntoggle-main\ntoggle-ext\n' | pick 'monitor')
    [ -n "$action" ] || exit 0
fi

case $action in
    layout)
        [ -n "$ext" ] || { echo "No external monitor connected." >&2; exit 1; }
        if [ -z "$choice" ]; then
            choice=$(printf 'top\nleft\nright\nbottom\n' | pick "$ext")
            [ -n "$choice" ] || exit 0
        fi
        set -- $(dims "$main"); mw=$1; mh=$2
        set -- $(dims "$ext");  ew=$1; eh=$2
        # Positions must not be negative (XWayland bug), so the layout is built from 0,0.
        case $choice in
            top)    main_x=0;   main_y=$eh; ext_x=0;  ext_y=0 ;;
            left)   main_x=$ew; main_y=0;   ext_x=0;  ext_y=0 ;;
            right)  main_x=0;   main_y=0;   ext_x=$mw; ext_y=0 ;;
            bottom) main_x=0;   main_y=0;   ext_x=0;  ext_y=$mh ;;
            *) echo "Unknown layout: $choice (use top, left, right or bottom)" >&2; exit 2 ;;
        esac
        apply_conf "$(edit_conf "$main=x:$main_x,y:$main_y" "$ext=x:$ext_x,y:$ext_y")"
        echo "External monitor $ext placed $choice of $main."
        ;;

    mode)
        target=$main
        if [ -n "$ext" ] && [ "$main" != "$ext" ]; then
            target=$(printf '%s\n%s\n' "$main" "$ext" | pick 'which display')
            [ -n "$target" ] || exit 0
        fi
        modes=$(randr_json | python3 -c '
import json, sys
for h in json.load(sys.stdin):
    if h["name"] != sys.argv[1]:
        continue
    seen = set()
    for m in h.get("modes", []):
        rate = round(m["refresh"])
        if (m["width"], m["height"], rate) in seen:
            continue
        seen.add((m["width"], m["height"], rate))
        print(str(m["width"]) + "x" + str(m["height"]) + "@" + str(rate)
              + (" *" if m.get("current") else ""))
    break
' "$target" 2>/dev/null) || modes=""
        if [ -z "$modes" ]; then
            echo "Cannot list modes: install wlr-randr (pacman -S wlr-randr)." >&2
            exit 1
        fi
        picked=$(printf '%s\n' "$modes" | pick "$target mode")
        [ -n "$picked" ] || exit 0
        picked=${picked% \*}
        w=${picked%%x*}; rest=${picked#*x}
        h=${rest%%@*};   r=${rest#*@}
        apply_conf "$(edit_conf "$target=width:$w,height:$h,refresh:$r")"
        echo "$target set to ${w}x${h}@${r}Hz."
        ;;

    toggle-main|toggle-ext)
        target=$main
        [ "$action" = toggle-ext ] && target=$ext
        [ -n "$target" ] || { echo "No external monitor connected." >&2; exit 1; }
        # Read the current disable flag out of the config; absent means enabled.
        dis=$(edit_conf | grep -F "name:^$target\$" | tr ',' '\n' | sed -n 's/^disable://p')
        dis=${dis:-0}
        new_dis=$((1 - dis))
        apply_conf "$(edit_conf "$target=disable:$new_dis")"
        if [ "$dry" -eq 0 ]; then
            if [ "$new_dis" = 1 ]; then
                mmsg dispatch disable_monitor,"$target" >/dev/null
                echo "Disabled $target."
            else
                mmsg dispatch enable_monitor,"$target" >/dev/null
                echo "Enabled $target."
            fi
        fi
        ;;

    *)
        echo "Usage: $0 [layout|mode|toggle-main|toggle-ext] [--dry-run]" >&2
        exit 2
        ;;
esac
