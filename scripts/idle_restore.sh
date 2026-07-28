#!/usr/bin/env bash
# Undo idle_takeover.sh: kill whichever hypridle is running and start the
# user's own back up (default config = ~/.config/hypr/hypridle.conf, ii's).
set -euo pipefail
pkill -x hypridle 2>/dev/null || true
sleep 0.3
setsid hypridle >/dev/null 2>&1 &
echo "user hypridle restored (default config)"
