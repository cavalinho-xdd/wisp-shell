#!/usr/bin/env bash
# apply_colors.sh [image] [scheme] [mode] [fanout]
#
# Generates a Material You palette from a wallpaper via matugen and writes it
# to colors.json next to shell.qml. Theme.qml watches that file.
#
# Optional 4th arg: comma list of extra fan-out targets from the same
# palette run. Currently supported:
#   "kitty" — renders scripts/templates/kitty-colors.conf into generated/,
#     and if the ii state file kitty already includes exists, copies over
#     it (ii regenerates that file on its next wallpaper change, so this is
#     self-healing, not a dotfile write) and live-reloads running kitties
#     via SIGUSR1.
#   "osc" — renders scripts/templates/terminal-osc.sh into generated/: a
#     terminal-agnostic recolor via OSC escape sequences (works in kitty,
#     alacritty, foot, wezterm, unlike the kitty-specific config above).
#     Not sourced automatically — no dotfile write here either. The user
#     adds one `source`/`cat` line to their own shell init (fish/bash/zsh)
#     pointing at generated/terminal-osc.sh; Settings' Colors page shows
#     the exact line to add.
#
# Sandbox: matugen is run with a throwaway empty config so the user's own
# ~/.config/matugen/config.toml (illogical-impulse, has sudo post_hooks) is
# never executed. No dotfile is read for writing; the ii wallpaper state file
# is only read as a fallback to find the current wallpaper.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Output goes to XDG state, never next to the QML: once wisp is installed
# as a package that directory is root-owned and read-only. Mirrors
# core/Paths.qml — keep the two in sync.
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/wisp"
mkdir -p "$STATE_DIR/generated"
OUT="$STATE_DIR/colors.json"

IMG="${1:-}"
SCHEME="${2:-tonal-spot}"
MODE="${3:-dark}"
FANOUT="${4:-}"

# Fallback: current wallpaper from the ii state file (read-only)
if [[ -z "$IMG" || "$IMG" == "-" ]]; then
    STATE="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/user/generated/wallpaper/path.txt"
    [[ -f "$STATE" ]] && IMG="$(head -1 "$STATE")"
fi
[[ -f "$IMG" ]] || { echo "no wallpaper image found" >&2; exit 1; }

CFG="$(mktemp)"
trap 'rm -f "$CFG"' EXIT
printf '[config]\nversion_check = false\n[templates]\n' > "$CFG"

GEN="$STATE_DIR/generated"
if [[ ",$FANOUT," == *",kitty,"* ]]; then
    mkdir -p "$GEN"
    printf '[templates.kitty]\ninput_path = "%s"\noutput_path = "%s"\n' \
        "$DIR/scripts/templates/kitty-colors.conf" "$GEN/kitty-colors.conf" >> "$CFG"
fi
if [[ ",$FANOUT," == *",osc,"* ]]; then
    mkdir -p "$GEN"
    printf '[templates.osc]\ninput_path = "%s"\noutput_path = "%s"\n' \
        "$DIR/scripts/templates/terminal-osc.sh" "$GEN/terminal-osc.sh" >> "$CFG"
fi

matugen image "$IMG" -c "$CFG" -t "scheme-$SCHEME" -m "$MODE" \
    --json hex -q --source-color-index 0 \
| jq --arg img "$IMG" --arg scheme "$SCHEME" --arg mode "$MODE" \
    '{wallpaper: $img, scheme: $scheme, mode: $mode,
      colors: (.colors | with_entries(.value |= .default.color))}' \
> "$OUT.tmp" && mv "$OUT.tmp" "$OUT"

if [[ ",$FANOUT," == *",kitty,"* && -f "$GEN/kitty-colors.conf" ]]; then
    # kitty.conf on this machine includes ii's generated theme — piggyback
    # on that include instead of touching kitty.conf itself
    II_KITTY="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/user/generated/terminal/kitty-theme.conf"
    [[ -f "$II_KITTY" ]] && cp "$GEN/kitty-colors.conf" "$II_KITTY"
    pkill -USR1 -x kitty 2>/dev/null || true
fi
