#!/bin/bash
# Fades the night-mode screen shader in (arg 1) or out (arg 0).
#
# Hyprland >= 0.55 runs the lua parser, where `hyprctl keyword` is rejected
# ("keyword can't work with non-legacy parsers"). Config is set with
# `hyprctl eval 'hl.config({...})'` instead.
#
# Each step writes a NEW file path. hl.config() may skip a write when the value
# is unchanged, so reusing one path could make the compositor ignore every frame
# after the first.
#
# Hyprland only checks that the shader path exists when it is set, and latches a
# "Failed to check screen shader path" error banner if it does not. So: never
# point the option at a file that is missing or about to be deleted. That means
# writing the frag before setting it, and serialising concurrent runs — a rapid
# on/off double-toggle would otherwise have one run rm -rf the dir while the
# other is still assigning paths inside it.
set -u

TARGET=$1
STEPS=20
# Fixed dir, not mktemp: the final frag stays referenced by the compositor for as
# long as night mode is on, so it must outlive this script.
DIR=/tmp/wisp-nightmode
LOCK=/tmp/wisp-nightmode.lock

# Serialise: a second toggle waits for the first fade to finish, then runs its
# own. Queued rather than pre-empted, so the shader value is never assigned by
# two runs at once.
exec 9>"$LOCK"
flock 9

mkdir -p "$DIR"

set_shader() {
    # Only assign a path that exists right now.
    if [ -r "$1" ]; then
        hyprctl eval "hl.config({ decoration = { screen_shader = \"$1\" } })" >/dev/null
    fi
}

if [ "$TARGET" = "1" ]; then
    SEQ=$(seq 0 1 $STEPS)
else
    SEQ=$(seq $STEPS -1 0)
fi

for i in $SEQ; do
    INTENSITY=$(echo "scale=2; $i/$STEPS" | bc)
    FRAG="$DIR/step_$i.frag"
    cat <<INNER_EOF > "$FRAG"
precision mediump float;
varying vec2 v_texcoord;
uniform sampler2D tex;
void main() {
    vec4 c = texture2D(tex, v_texcoord);
    vec4 f = c;
    f.b *= 0.6;
    f.g *= 0.85;
    f.r *= 1.05;
    gl_FragColor = mix(c, f, $INTENSITY);
}
INNER_EOF
    set_shader "$FRAG"
    sleep 0.05
done

if [ "$TARGET" = "0" ]; then
    # Unset first, delete second — never leave the option pointing at a dead path.
    # Sentinel is [[EMPTY]], uppercase. The wiki's default column shows
    # "[[Empty]]"; `hyprctl getoption decoration:screen_shader` after a reload
    # reports "[[EMPTY]]". Trust the compositor, not the wiki, on this one —
    # if the sentinel is not matched it is treated as a literal file path and
    # Hyprland raises "Failed to check screen shader path".
    hyprctl eval 'hl.config({ decoration = { screen_shader = "[[EMPTY]]" } })' >/dev/null
    rm -rf "$DIR"
else
    # Keep only the fully-faded shader that is now live.
    find "$DIR" -name 'step_*.frag' ! -name "step_$STEPS.frag" -delete
fi
