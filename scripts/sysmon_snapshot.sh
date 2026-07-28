#!/bin/bash
while true; do
    # Memory
    RAM_TOTAL=$(free -m | awk '/^Mem:/ {printf "%.1f", $2/1024}')
    RAM_USED=$(free -m | awk '/^Mem:/ {printf "%.1f", $3/1024}')
    RAM_FREE=$(free -m | awk '/^Mem:/ {printf "%.1f", $7/1024}')
    
    # Swap
    SWAP_TOTAL=$(free -m | awk '/^Swap:/ {printf "%.1f", $2/1024}')
    SWAP_USED=$(free -m | awk '/^Swap:/ {printf "%.1f", $3/1024}')
    SWAP_FREE=$(free -m | awk '/^Swap:/ {printf "%.1f", $4/1024}')
    
    # CPU Load
    read cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
    previdle=$idle
    prevtotal=$((user+nice+system+idle+iowait+irq+softirq+steal))
    
    sleep 1.0
    
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
    # GPU Load (nvidia-smi)
    gpu_load=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null || echo 0)
    
    # Top 5 CPU Processes (format to JSON string array)
    top_procs=$(ps -eo pcpu,pmem,comm --sort=-pcpu | head -n 6 | tail -n 5 | awk '{
        cpu=$1; mem=$2; 
        $1=""; $2=""; 
        name=substr($0, 3); 
        printf "{\"name\": \"%s\", \"cpu\": \"%s%\", \"mem\": \"%s%%\"},", name, cpu, mem
    }' | sed 's/,$//')
    
    echo "{ \"ram\": { \"used\": \"$RAM_USED GB\", \"free\": \"$RAM_FREE GB\", \"total\": \"$RAM_TOTAL GB\", \"value\": $(echo "$RAM_USED / $RAM_TOTAL" | bc -l 2>/dev/null || echo 0) }, \"swap\": { \"used\": \"$SWAP_USED GB\", \"free\": \"$SWAP_FREE GB\", \"total\": \"$SWAP_TOTAL GB\", \"value\": $(echo "$SWAP_USED / $SWAP_TOTAL" | bc -l 2>/dev/null || echo 0) }, \"cpu\": { \"load\": \"${cpu_load}%\", \"value\": $(echo "$cpu_load / 100" | bc -l) }, \"gpu\": { \"load\": \"${gpu_load}%\", \"value\": $(echo "$gpu_load / 100" | bc -l) }, \"top\": [$top_procs] }"
done
