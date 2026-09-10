#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")/Screenshots"
mkdir -p "$TARGET_DIR"

GEOM="$(slurp 2>/dev/null)" || exit 0
[ -n "$GEOM" ] || exit 0

FILE="$TARGET_DIR/screenshot_$(date +'%Y-%m-%d_%H-%M-%S').png"

grim -g "$GEOM" "$FILE"
wl-copy --type image/png < "$FILE"

notify-send -a "Wisp" -i "$FILE" "Snímek obrazovky" "Zkopírováno do schránky a uloženo do $(basename "$TARGET_DIR")."
