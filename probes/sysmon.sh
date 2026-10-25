#!/bin/bash
CORES=$(nproc 2>/dev/null || echo 1)

# Network initial
read -r rx_bytes tx_bytes < <(awk '/^ *(en|wl|eth|wlan)/ { rx+=$2; tx+=$10 } END { print rx, tx }' /proc/net/dev)
prev_rx=$rx_bytes
prev_tx=$tx_bytes

# CPU initial
read cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
previdle=$idle
prevtotal=$((user+nice+system+idle+iowait+irq+softirq+steal))

sleep 1.0

# Network next
read -r rx_bytes tx_bytes < <(awk '/^ *(en|wl|eth|wlan)/ { rx+=$2; tx+=$10 } END { print rx, tx }' /proc/net/dev)
rx_diff=$((rx_bytes - prev_rx))
tx_diff=$((tx_bytes - prev_tx))

# Convert to human readable
human_net() {
    local b=$1
    if [ $b -gt 1048576 ]; then
        awk "BEGIN { printf \"%.1f MB/s\", $b / 1048576 }"
    elif [ $b -gt 1024 ]; then
        awk "BEGIN { printf \"%.1f KB/s\", $b / 1024 }"
    else
        echo "$b B/s"
    fi
}
rx_human=$(human_net $rx_diff)
tx_human=$(human_net $tx_diff)

# Disk
read -r disk_total disk_used disk_free disk_pct < <(df -BG / | awk 'NR==2 { gsub("G", "", $2); gsub("G", "", $3); gsub("G", "", $4); gsub("%", "", $5); print $2, $3, $4, $5 }')
disk_val=$(awk "BEGIN { print $disk_pct / 100 }")

echo "Disk: $disk_used / $disk_total ($disk_val)"
echo "Net: RX $rx_human, TX $tx_human"
