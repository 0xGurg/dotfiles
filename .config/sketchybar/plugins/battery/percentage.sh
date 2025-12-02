#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"

BATT_INFO=$(pmset -g batt)
PERCENTAGE=$(echo "$BATT_INFO" | grep -Eo "\d+%" | cut -d% -f1)
CHARGING=$(echo "$BATT_INFO" | grep 'AC Power')

if [ -z "$PERCENTAGE" ]; then
  sketchybar --set "$NAME" label="N/A" label.color=$TEXT_COLOR
  exit 0
fi

# Set icon based on charging status
if [ -n "$CHARGING" ]; then
  ICON="􀫯"
else
  ICON="􁠸"
fi

# Build percentage label
PERCENTAGE_LABEL="${PERCENTAGE}%"

# Color based on percentage (matching battery.sh logic)
if [ -n "$CHARGING" ]; then
  COLOR=$BLUE
elif [ "$PERCENTAGE" -ge 90 ]; then
  COLOR=$ICON_COLOR
elif [ "$PERCENTAGE" -ge 60 ]; then
  COLOR=$GREEN
elif [ "$PERCENTAGE" -ge 30 ]; then
  COLOR=$YELLOW
elif [ "$PERCENTAGE" -ge 10 ]; then
  COLOR=$ORANGE
else
  COLOR=$RED
fi

# Update percentage item
sketchybar --set "$NAME" \
  icon="$ICON" \
  icon.color=$COLOR \
  label="$PERCENTAGE_LABEL"
