#!/usr/bin/env bash
# Runs a theme in sddm-greeter-qt6's test mode for a few seconds, screenshots
# its window and fails if the log has errors or warnings from the theme.
# Usage: sddm/check-greeter.sh [theme-dir] [out.png] [seconds]
# ALLOW=<regex> skips matching log lines (e.g. the missing-background test).
set -u
theme=$(realpath "${1:-$(dirname "$0")/wisp-ember}")
out=${2:-/tmp/wisp-greeter.png}
secs=${3:-4}
log=${out%.png}.log
[ -f "$theme/Main.qml" ] || { echo "FAIL: no $theme/Main.qml"; exit 1; }

sddm-greeter-qt6 --test-mode --theme "$theme" >"$log" 2>&1 &
pid=$!
sleep "$secs"
geo=$(hyprctl clients -j | jq -r --argjson p "$pid" '.[] | select(.pid == $p) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' | head -1)
if [ -n "$geo" ]; then grim -g "$geo" "$out"; else grim "$out"; fi
kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null
# The greeter logs to the journal, not to stderr.
sleep 0.3; journalctl --user _PID="$pid" -o cat >>"$log" 2>/dev/null

# Lines that name the theme's own files, plus QML errors without a path.
bad=$(grep -E "wisp-ember|$theme" "$log" | grep -iE 'error|warn|unavailable|not defined|undefined|cannot|failed|TypeError|ReferenceError' | grep -vE "${ALLOW:-^\$}" || true)
if [ -n "$bad" ]; then echo "FAIL:"; echo "$bad"; exit 1; fi
echo "OK: $out (log $log)"
