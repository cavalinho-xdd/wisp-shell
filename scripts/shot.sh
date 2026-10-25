#!/usr/bin/env bash
# Screenshot of the island area (top strip of every monitor) for before/after
# checks. Saves docs/screens/<name>-<monitor>.png (git-ignored).
#
#   scripts/shot.sh <name> [height]    # height of the strip, default 520
set -euo pipefail

NAME="${1:?usage: scripts/shot.sh <name> [height]}"
HEIGHT="${2:-520}"
OUT_DIR="$(cd "$(dirname "$0")/.." && pwd)/docs/screens"
mkdir -p "$OUT_DIR"

hyprctl monitors -j | jq -r '.[] | "\(.name) \(.x) \(.y) \(.width / .scale | floor)"' |
while read -r mon x y w; do
    file="$OUT_DIR/$NAME-$mon.png"
    grim -g "$x,$y ${w}x$HEIGHT" "$file"
    echo "$file"
done
