#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"

# Get disk usage
DISK_FREE_RAW=$(df -h / | tail -1 | awk '{print $4}')
DISK_PERCENT=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')

# Extract number (remove all non-numeric except decimal point)
DISK_NUM=$(echo "$DISK_FREE_RAW" | sed 's/[^0-9.]//g')
# Extract unit (all letters at the end)
DISK_UNIT=$(echo "$DISK_FREE_RAW" | sed 's/[0-9.]//g')

# Convert to GB format
if [ "$DISK_UNIT" = "Ti" ] || [ "$DISK_UNIT" = "T" ]; then
  DISK_GB=$(echo "scale=0; $DISK_NUM * 1024" | bc)
elif [ "$DISK_UNIT" = "Gi" ] || [ "$DISK_UNIT" = "G" ]; then
  DISK_GB=$(printf "%.0f" "$DISK_NUM")
elif [ "$DISK_UNIT" = "Mi" ] || [ "$DISK_UNIT" = "M" ]; then
  DISK_GB=$(echo "scale=0; $DISK_NUM / 1024" | bc)
else
  DISK_GB=$DISK_NUM
fi

# Color based on percentage used
if [ "$DISK_PERCENT" -ge 90 ]; then
  COLOR=$RED
elif [ "$DISK_PERCENT" -ge 75 ]; then
  COLOR=$YELLOW
elif [ "$DISK_PERCENT" -ge 50 ]; then
  COLOR=$GREEN
else
  COLOR=$ICON_COLOR
fi

sketchybar --set "$NAME" label="${DISK_GB} GB" icon.color=$COLOR
