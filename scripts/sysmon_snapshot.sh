#!/bin/bash
CORES=$(nproc 2>/dev/null || echo 1)
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
    gpu_load=0
    if command -v nvidia-smi >/dev/null 2>&1; then
        gpu_load=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null || echo 0)
    elif [ -f /sys/class/drm/card0/device/gpu_busy_percent ] || [ -f /sys/class/drm/card1/device/gpu_busy_percent ]; then
        amd_busy_file=$(ls /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null | head -n 1 || true)
        gpu_load=$(cat "$amd_busy_file" 2>/dev/null || echo 0)
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
    
    echo "{ \"ram\": { \"used\": \"$RAM_USED GB\", \"free\": \"$RAM_FREE GB\", \"total\": \"$RAM_TOTAL GB\", \"value\": $(echo "$RAM_USED / $RAM_TOTAL" | bc -l 2>/dev/null || echo 0) }, \"swap\": { \"used\": \"$SWAP_USED GB\", \"free\": \"$SWAP_FREE GB\", \"total\": \"$SWAP_TOTAL GB\", \"value\": $(echo "$SWAP_USED / $SWAP_TOTAL" | bc -l 2>/dev/null || echo 0) }, \"cpu\": { \"load\": \"${cpu_load}%\", \"value\": $(echo "$cpu_load / 100" | bc -l) }, \"gpu\": { \"load\": \"${gpu_load}%\", \"value\": $(echo "$gpu_load / 100" | bc -l) }, \"top\": [$top_procs] }"
done
