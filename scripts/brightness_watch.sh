#!/bin/bash
BL_DIR=$(ls -d /sys/class/backlight/* 2>/dev/null | head -n 1)
if [ -z "$BL_DIR" ]; then exit 1; fi

get_brightness() {
    local val=$(cat "$BL_DIR/brightness")
    local max=$(cat "$BL_DIR/max_brightness")
    echo "{\"value\": $(awk "BEGIN {print $val / $max}")}"
}

# Initial print
get_brightness

stdbuf -oL udevadm monitor --udev --subsystem-match=backlight | while read -r line; do
    if [[ "$line" == *"change"* && "$line" == *"(backlight)"* ]]; then
        get_brightness
    fi
done
