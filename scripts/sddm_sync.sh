#!/usr/bin/env bash
# Copies the wallpaper and the ember colour into the installed Wisp Ember
# login screen. The greeter runs as the sddm user and cannot read $HOME, so
# it gets its own copy. Runs as root through pkexec (Settings.applyLoginScreen).
#
# Usage: sddm_sync.sh [--apply] <wallpaper> <ember #rrggbb> <glow>
# Without --apply it only prints what it would do.
#
# SDDM 0.21 reads theme.conf.user over theme.conf (checked in test mode), so
# the shipped theme.conf stays untouched.
set -eu

apply=0
if [ "${1:-}" = "--apply" ]; then apply=1; shift; fi
if [ $# -ne 3 ]; then
    echo "Usage: $0 [--apply] <wallpaper> <ember #rrggbb> <glow>" >&2
    exit 2
fi
wallpaper=$1 ember=$2 glow=$3
# Overridable for tests only; pkexec clears the environment.
dir=${WISP_SDDM_THEME_DIR:-/usr/share/sddm/themes/wisp-ember}

# The values come from the user's config and end up in a root-written file.
if ! [[ $ember =~ ^#[0-9a-fA-F]{6}$ ]]; then
    echo "Ember must be #rrggbb, got: $ember" >&2; exit 2
fi
if ! [[ $glow =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    echo "Glow must be a number, got: $glow" >&2; exit 2
fi
if [ ! -d "$dir" ]; then
    echo "Wisp Ember login theme is not installed ($dir missing). Run: setup bootstrap" >&2; exit 1
fi
if [ ! -f "$wallpaper" ] || [ ! -r "$wallpaper" ]; then
    echo "Wallpaper is not a readable file: $wallpaper" >&2; exit 1
fi
# Root reads it and the copy is world-readable: only ever copy an image.
case $(file -b --mime-type -- "$wallpaper") in
    image/*) ;;
    *) echo "Wallpaper is not an image: $wallpaper" >&2; exit 1 ;;
esac

if [ $apply -eq 0 ]; then
    echo "would copy $wallpaper -> $dir/background.jpg"
    echo "would write ember=$ember glow=$glow -> $dir/theme.conf.user"
    exit 0
fi

# Downscaled: the greeter blurs it to 40 px anyway. Written to a temp file
# first so a failed conversion never leaves a broken background.
tmp=$(mktemp "$dir/.background.XXXXXX.jpg")
trap 'rm -f "$tmp"' EXIT
if command -v magick >/dev/null 2>&1; then
    magick "$wallpaper[0]" -resize '2560x>' -quality 90 "$tmp"
else
    cp "$wallpaper" "$tmp"
fi
chmod 644 "$tmp"
mv "$tmp" "$dir/background.jpg"
trap - EXIT

printf '[General]\nember=%s\nglow=%s\n' "$ember" "$glow" > "$dir/theme.conf.user"
chmod 644 "$dir/theme.conf.user"
echo "Login screen updated: $dir"
