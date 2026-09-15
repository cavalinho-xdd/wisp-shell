#!/bin/bash
# Monitor udev for USB connects/disconnects (devices only, ignore interfaces).

stdbuf -oL udevadm monitor --udev --subsystem-match=usb --property | awk '
/^ACTION=add/ { action="add" }
/^ACTION=remove/ { action="remove" }
/^DEVTYPE=usb_device/ {
    if (action != "") {
        print "{\"event\": \"" action "\"}"
        fflush()
        action = ""
    }
}'
