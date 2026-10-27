#!/bin/bash
CORES=$(nproc 2>/dev/null || echo 1)

# JSON needs "0.51", not bc's ".51"; an empty or zero total gives 0
ratio() {
    awk -v a="$1" -v b="$2" 'BEGIN { printf "%.4f", (b + 0 > 0) ? a / b : 0 }'
}

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

read -r prev_rx prev_tx < <(awk '/^ *(en|wl|eth|wlan)/ { rx+=$2; tx+=$10 } END { print rx+0, tx+0 }' /proc/net/dev)

while true; do
    # Memory
    RAM_TOTAL=$(free -m | awk '/^Mem:/ {printf "%.1f", $2/1024}')
    RAM_USED=$(free -m | awk '/^Mem:/ {printf "%.1f", $3/1024}')
    RAM_FREE=$(free -m | awk '/^Mem:/ {printf "%.1f", $7/1024}')
    
    # Swap
    SWAP_TOTAL=$(free -m | awk '/^Swap:/ {printf "%.1f", $2/1024}')
    SWAP_USED=$(free -m | awk '/^Swap:/ {printf "%.1f", $3/1024}')
    SWAP_FREE=$(free -m | awk '/^Swap:/ {printf "%.1f", $4/1024}')
    
    # CPU Load & Intel GPU sample 1
    read cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
    previdle=$idle
    prevtotal=$((user+nice+system+idle+iowait+irq+softirq+steal))
    
    intel_rc6_file=$(ls /sys/class/drm/card*/power/rc6_residency_ms /sys/class/drm/card*/gt/gt0/rc6_residency_ms 2>/dev/null | head -n 1 || true)
    if [ -n "$intel_rc6_file" ] && [ -r "$intel_rc6_file" ]; then
        rc6_before=$(cat "$intel_rc6_file" 2>/dev/null || echo 0)
        time_before=$(date +%s%3N)
    fi

    sleep 1.0
    
    # Network Diff
    read -r rx_bytes tx_bytes < <(awk '/^ *(en|wl|eth|wlan)/ { rx+=$2; tx+=$10 } END { print rx+0, tx+0 }' /proc/net/dev)
    rx_diff=$((rx_bytes - prev_rx))
    tx_diff=$((tx_bytes - prev_tx))
    prev_rx=$rx_bytes
    prev_tx=$tx_bytes
    
    rx_human=$(human_net $rx_diff)
    tx_human=$(human_net $tx_diff)

    # Disk
    read -r disk_total disk_used disk_free disk_pct < <(df -BG / | awk 'NR==2 { gsub("G", "", $2); gsub("G", "", $3); gsub("G", "", $4); gsub("%", "", $5); print $2, $3, $4, $5 }')
    disk_val=$(awk "BEGIN { print $disk_pct / 100 }")
    
    # CPU Load & Intel GPU sample 2
    read cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
    idle=$idle
    total=$((user+nice+system+idle+iowait+irq+softirq+steal))
    
    diff_idle=$((idle-previdle))
    diff_total=$((total-prevtotal))
    if [ $diff_total -eq 0 ]; then
        cpu_load=0
    else
        cpu_load=$((100 * (diff_total - diff_idle) / diff_total))
    fi

    # GPU Load (Nvidia -> AMD -> Intel)
    # nvidia-smi can be installed without a working driver and prints an error instead of a number
    gpu_load=""
    if command -v nvidia-smi >/dev/null 2>&1; then
        gpu_load=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -n 1 | tr -dc '0-9')
    fi
    amd_busy_file=$(ls /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null | head -n 1 || true)
    if [ -n "$gpu_load" ]; then
        :
    elif [ -n "$amd_busy_file" ]; then
        gpu_load=$(tr -dc '0-9' < "$amd_busy_file")
    elif [ -n "$intel_rc6_file" ] && [ -r "$intel_rc6_file" ]; then
        rc6_after=$(cat "$intel_rc6_file" 2>/dev/null || echo 0)
        time_after=$(date +%s%3N)
        dt=$((time_after - time_before))
        drc6=$((rc6_after - rc6_before))
        if [ $dt -gt 0 ] && [ $drc6 -le $dt ]; then
            gpu_load=$(( 100 - (drc6 * 100 / dt) ))
        else
            gpu_load=0
        fi
        [ $gpu_load -lt 0 ] && gpu_load=0
        [ $gpu_load -gt 100 ] && gpu_load=100
    fi
    gpu_load=${gpu_load:-0}
    
    # Top 5 CPU Processes (exclude self, normalize CPU across cores)
    top_procs=$(ps -eo pcpu,pmem,comm --sort=-pcpu | awk -v cores="$CORES" '
        NR > 1 && $3 != "ps" && $3 != "sysmon_snapshot.sh" && $3 != "sysmon_snapshot" && $3 != "awk" && $3 != "sed" {
            cpu=sprintf("%.1f", $1 / cores);
            mem=sprintf("%.1f", $2);
            $1=""; $2="";
            name=substr($0, 3);
            printf "{\"name\": \"%s\", \"cpu\": \"%s%%\", \"mem\": \"%s%%\"},", name, cpu, mem;
            count++;
            if (count >= 5) exit;
        }
    ' | sed 's/,$//')
    
    echo "{ \"ram\": { \"used\": \"$RAM_USED GB\", \"free\": \"$RAM_FREE GB\", \"total\": \"$RAM_TOTAL GB\", \"value\": $(ratio "$RAM_USED" "$RAM_TOTAL") }, \"swap\": { \"used\": \"$SWAP_USED GB\", \"free\": \"$SWAP_FREE GB\", \"total\": \"$SWAP_TOTAL GB\", \"value\": $(ratio "$SWAP_USED" "$SWAP_TOTAL") }, \"cpu\": { \"load\": \"${cpu_load}%\", \"value\": $(ratio "$cpu_load" 100) }, \"gpu\": { \"load\": \"${gpu_load}%\", \"value\": $(ratio "$gpu_load" 100) }, \"disk\": { \"used\": \"${disk_used}G\", \"total\": \"${disk_total}G\", \"value\": ${disk_val} }, \"net\": { \"rx\": \"${rx_human}\", \"tx\": \"${tx_human}\" }, \"top\": [$top_procs] }"
done
