#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"

PREV_DOWN_FILE="/tmp/sketchybar_net_down"

# Get download speed
INTERFACE=$(route get default 2>/dev/null | grep interface | awk '{print $2}')

if [ -n "$INTERFACE" ]; then
  CURRENT=$(netstat -ib -I "$INTERFACE" 2>/dev/null | tail -1 | awk '{print $7}')
  
  if [ -f "$PREV_DOWN_FILE" ]; then
    PREV=$(cat "$PREV_DOWN_FILE")
    DIFF=$((CURRENT - PREV))
    # Calculate speed in KB/s (netstat shows bytes, divide by 1024 and by update interval)
    SPEED=$((DIFF / 1024 / 2))
    
    if [ $SPEED -ge 1024 ]; then
      SPEED_MB=$(echo "scale=1; $SPEED / 1024" | bc)
      sketchybar --set "$NAME" label="${SPEED_MB} MB/s"
    else
      sketchybar --set "$NAME" label="${SPEED} KB/s"
    fi
  else
    sketchybar --set "$NAME" label="0 KB/s"
  fi
  
  echo "$CURRENT" > "$PREV_DOWN_FILE"
else
  sketchybar --set "$NAME" label="No connection"
fi
