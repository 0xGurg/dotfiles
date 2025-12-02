#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"

# Get CPU usage
CPU_USAGE=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')
CPU_INT=$(printf "%.0f" "$CPU_USAGE" 2>/dev/null || echo "0")

if [ "$CPU_INT" -ge 80 ]; then
  COLOR=$RED
elif [ "$CPU_INT" -ge 50 ]; then
  COLOR=$YELLOW
elif [ "$CPU_INT" -ge 20 ]; then
  COLOR=$GREEN
else
  COLOR=$ICON_COLOR
fi

sketchybar --set "$NAME" label="${CPU_INT}%" icon.color=$COLOR
