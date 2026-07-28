#!/usr/bin/env bash
# Swap idle handling to Wisp: stop the dotfiles' hypridle (ii's, spawned
# by Hyprland exec-once — not a systemd unit) and start ours with the
# project-local config. Fully reversible: scripts/idle_restore.sh.
set -euo pipefail
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

pkill -x hypridle 2>/dev/null || true
sleep 0.3
setsid hypridle -c "$dir/hypridle.conf" >/dev/null 2>&1 &
echo "Wisp hypridle running (config: $dir/hypridle.conf)"
