#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"

# Get RAM usage from vm_stat (only count active + wired as used)
PAGE_SIZE=$(pagesize)
PAGES=$(vm_stat)

# Get page counts
ACTIVE=$(echo "$PAGES" | grep "Pages active" | awk '{print $3}' | tr -d '.')
WIRED=$(echo "$PAGES" | grep "Pages wired down" | awk '{print $4}' | tr -d '.')

# Calculate used memory (only active + wired, not inactive)
USED_PAGES=$((ACTIVE + WIRED))
USED_BYTES=$((USED_PAGES * PAGE_SIZE))

TOTAL_BYTES=$(sysctl -n hw.memsize)

if [ -n "$TOTAL_BYTES" ] && [ -n "$USED_BYTES" ] && [ "$TOTAL_BYTES" != "0" ]; then
  RAM_PERCENT=$(awk "BEGIN {printf \"%.0f\", ($USED_BYTES / $TOTAL_BYTES) * 100}")
  
  if [ "$RAM_PERCENT" -ge 80 ]; then
    COLOR=$RED
  elif [ "$RAM_PERCENT" -ge 60 ]; then
    COLOR=$YELLOW
  elif [ "$RAM_PERCENT" -ge 20 ]; then
    COLOR=$GREEN
  else
    COLOR=$ICON_COLOR
  fi
  
  sketchybar --set "$NAME" label="${RAM_PERCENT}%" icon.color=$COLOR
else
  sketchybar --set "$NAME" label="N/A" icon.color=$TEXT_COLOR
fi
