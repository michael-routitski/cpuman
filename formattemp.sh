#!/usr/bin/env bash

CLR="\033[K"
STATE_FILE="/tmp/cpuman_auto_target"

MIN_CAP=1.5
MAX_CAP=3.6

if [[ ! -f "$STATE_FILE" ]]; then
    if [[ -f /etc/cpuman_cap.conf ]]; then
        val=$(awk '{print $1}' /etc/cpuman_cap.conf 2>/dev/null)
        if [[ "$val" =~ ^[0-9.]+$ ]]; then 
            echo "$val" > "$STATE_FILE"
        fi
    fi
    if [[ ! -f "$STATE_FILE" ]]; then 
        echo "2.5" > "$STATE_FILE"
    fi
fi

CURRENT_CAP=$(awk '{printf "%.1f", $1}' "$STATE_FILE" 2>/dev/null || echo "2.5")

# Parse Core Temperatures (Physical Cores)
mapfile -t CORES_TEMP < <(sensors 2>/dev/null | grep -E '^Core [0-9]+:' | awk -F':' '{print $2}' | awk '{print $1}' | tr -d '+°C')

# Parse Core Speeds for ALL Logical Cores (MHz)
mapfile -t RAW_LOGICAL_SPEEDS < <(grep 'cpu MHz' /proc/cpuinfo | awk '{print $4}')

NUM_PHYS_CORES=${#CORES_TEMP[@]}
NUM_LOGICAL_CORES=${#RAW_LOGICAL_SPEEDS[@]}

# Average logical core speeds into physical core speeds
PHYS_SPEEDS=()
if [[ "$NUM_LOGICAL_CORES" -gt 0 && "$NUM_PHYS_CORES" -gt 0 ]]; then
    THREADS_PER_CORE=$(( NUM_LOGICAL_CORES / NUM_PHYS_CORES ))
    for ((i=0; i<NUM_PHYS_CORES; i++)); do
        sum=0
        for ((t=0; t<THREADS_PER_CORE; t++)); do
            idx=$(( i + (t * NUM_PHYS_CORES) ))
            speed_val="${RAW_LOGICAL_SPEEDS[$idx]}"
            sum=$(awk -v s="$sum" -v v="$speed_val" 'BEGIN { print s + v }')
        done
        avg_ghz=$(awk -v s="$sum" -v t="$THREADS_PER_CORE" 'BEGIN { printf "%.2f", (s / t) / 1000 }')
        PHYS_SPEEDS+=("$avg_ghz")
    done
fi

# Determine Maximum Temperature across physical cores
MAX_TEMP=0
for temp in "${CORES_TEMP[@]}"; do
    temp_int=${temp%.*}
    if [[ -n "$temp_int" && "$temp_int" -gt "$MAX_TEMP" ]]; then
        MAX_TEMP=$temp_int
    fi
done

# Evaluate Throttle Action (Target Band: 60°C to 70°C)
THROTTLE_STATUS="Throttle: Unchanged"

if [[ "$MAX_TEMP" -gt 70 ]]; then
    NEW_CAP=$(awk -v c="$CURRENT_CAP" -v step="0.2" -v min="$MIN_CAP" 'BEGIN {
        n = c - step;
        if (n < min) n = min;
        printf "%.1f", n
    }')

    IS_CHANGED=$(awk -v old="$CURRENT_CAP" -v new="$NEW_CAP" 'BEGIN { if (old != new) print "1"; else print "0"; }')

    if [[ "$IS_CHANGED" -eq 1 ]]; then
        THROTTLE_STATUS="Throttle: Decreased Cap (${CURRENT_CAP} -> ${NEW_CAP} GHz | Max Temp: ${MAX_TEMP}°C)"
        sudo /usr/local/bin/cpuman cap-speed "$NEW_CAP" &>/dev/null
        echo "$NEW_CAP" > "$STATE_FILE"
        CURRENT_CAP="$NEW_CAP"
    else
        THROTTLE_STATUS="Throttle: Unchanged (At Min Limit: ${MIN_CAP} GHz | Max Temp: ${MAX_TEMP}°C)"
    fi

elif [[ "$MAX_TEMP" -lt 60 && "$MAX_TEMP" -gt 0 ]]; then
    NEW_CAP=$(awk -v c="$CURRENT_CAP" -v step="0.2" -v max="$MAX_CAP" 'BEGIN {
        n = c + step;
        if (n > max) n = max;
        printf "%.1f", n
    }')

    IS_CHANGED=$(awk -v old="$CURRENT_CAP" -v new="$NEW_CAP" 'BEGIN { if (old != new) print "1"; else print "0"; }')

    if [[ "$IS_CHANGED" -eq 1 ]]; then
        THROTTLE_STATUS="Throttle: Increased Cap (${CURRENT_CAP} -> ${NEW_CAP} GHz | Max Temp: ${MAX_TEMP}°C)"
        sudo /usr/local/bin/cpuman cap-speed "$NEW_CAP" &>/dev/null
        echo "$NEW_CAP" > "$STATE_FILE"
        CURRENT_CAP="$NEW_CAP"
    else
        THROTTLE_STATUS="Throttle: Unchanged (At Max Limit: ${MAX_CAP} GHz | Max Temp: ${MAX_TEMP}°C)"
    fi

else
    THROTTLE_STATUS="Throttle: Unchanged (In Target Range 60-70°C | Max Temp: ${MAX_TEMP}°C)"
fi

# Print Status Header Lines
echo -e "${THROTTLE_STATUS}${CLR}"
echo -e "Active Speed Limit: ${CURRENT_CAP} GHz${CLR}"
echo -e "${CLR}"

# Combined Single Table (Width: 8 chars per column)
header_core=$(printf "%-8s" "Core")
header_temp=$(printf "%-8s" "Temp")
header_speed=$(printf "%-8s" "Speed")

for ((i=0; i<NUM_PHYS_CORES; i++)); do
    header_core+=$(printf " | %-8s" "Core $i")
    header_temp+=$(printf " | %-9s" "${CORES_TEMP[$i]}°C")
    header_speed+=$(printf " | %-8s" "${PHYS_SPEEDS[$i]} GHz")
done

echo -e "${header_core}${CLR}"
echo -e "${header_temp}${CLR}"
echo -e "${header_speed}${CLR}"
