#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"

# Try to get actual CPU temperature
if command -v osx-cpu-temp &> /dev/null; then
  # Use osx-cpu-temp if available
  TEMP_C=$(osx-cpu-temp | sed 's/°C//' | awk '{print $1}')
else
  # Try powermetrics (may require sudo setup)
  TEMP_C=$(sudo powermetrics --samplers smc -i1 -n1 2>/dev/null | grep "CPU die temperature" | awk '{print $4}' | sed 's/°C//')
  
  # If still no temperature, estimate based on CPU usage
  if [ -z "$TEMP_C" ]; then
    CPU_USAGE=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')
    CPU_INT=$(printf "%.0f" "$CPU_USAGE" 2>/dev/null || echo "0")
    # Rough estimate: 40°C base + CPU usage percentage / 2
    TEMP_C=$(echo "scale=0; 40 + $CPU_INT / 2" | bc)
  fi
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
