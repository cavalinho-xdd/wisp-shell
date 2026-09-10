#!/usr/bin/env bash
if [ -z "$1" ]; then
    echo "Usage: $0 <Theme Name>"
    exit 1
fi
pkexec sed -i "s/^Current=.*/Current=$1/" /etc/sddm.conf.d/wisp.conf
