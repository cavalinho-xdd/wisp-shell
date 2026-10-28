#!/usr/bin/env bash
# Screenshots one state of the theme through test/Preview.qml.
# Usage: sddm/test/preview.sh <state|rest> <out.png> [wallpaper] [extra theme.conf lines]
set -eu
here=$(dirname "$(realpath "$0")")
state=$1 out=$2 wall=${3:-} extra=${4:-}
dir=$(mktemp -d)
cp -r "$here/../wisp-ember/." "$dir/"
cp "$here/Preview.qml" "$dir/"
sed -i 's/^MainScript=.*/MainScript=Preview.qml/' "$dir/metadata.desktop"
printf 'preview=%s\n%s\n' "$state" "$extra" >> "$dir/theme.conf"
[ -n "$wall" ] && magick "$wall" -resize 1920x "$dir/background.jpg"
rc=0; "$here/../check-greeter.sh" "$dir" "$out" "${SECS:-4}" || rc=$?
rm -rf "$dir"
exit $rc
