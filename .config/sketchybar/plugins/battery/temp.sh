#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"

# Try to get actual CPU temperature using macmon
if command -v macmon &> /dev/null; then
  # Use macmon pipe mode to get JSON output (no sudo required!)
  # head -1 will cause SIGPIPE which terminates macmon automatically
  TEMP_C=$(macmon pipe 2>&1 | head -1 | grep -o '"cpu_temp_avg":[0-9.]*' | cut -d':' -f2)
  
  # If macmon fails or returns empty, fall back to estimation
  if [ -z "$TEMP_C" ]; then
    CPU_USAGE=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')
    CPU_INT=$(printf "%.0f" "$CPU_USAGE" 2>/dev/null || echo "0")
    TEMP_C=$(echo "scale=0; 40 + $CPU_INT / 2" | bc)
  fi
else
  # Fallback: estimate based on CPU usage if macmon is not installed
  CPU_USAGE=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')
  CPU_INT=$(printf "%.0f" "$CPU_USAGE" 2>/dev/null || echo "0")
  # Rough estimate: 40°C base + CPU usage percentage / 2
  TEMP_C=$(echo "scale=0; 40 + $CPU_INT / 2" | bc)
fi

# Convert to integer if needed
TEMP_INT=$(printf "%.0f" "$TEMP_C" 2>/dev/null || echo "50")

# Color based on temperature
if [ "$TEMP_INT" -ge 80 ]; then
  COLOR=$RED
elif [ "$TEMP_INT" -ge 70 ]; then
  COLOR=$YELLOW
elif [ "$TEMP_INT" -ge 50 ]; then
  COLOR=$GREEN
else
  COLOR=$ICON_COLOR
fi

sketchybar --set "$NAME" label="${TEMP_INT}°C" icon.color=$COLOR
