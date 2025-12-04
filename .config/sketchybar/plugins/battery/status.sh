#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"

BATT_INFO=$(pmset -g batt)
PERCENTAGE=$(echo "$BATT_INFO" | grep -Eo "[0-9]+%" | cut -d% -f1)
CHARGING=$(echo "$BATT_INFO" | grep 'AC Power')

# Get time remaining (format: X:XX remaining or X:XX until charged)
TIME_REMAINING=$(echo "$BATT_INFO" | grep -oE "[0-9]+:[0-9]+" | head -1)

# Check for special states
NO_ESTIMATE=$(echo "$BATT_INFO" | grep -o "(no estimate)")
CHARGED=$(echo "$BATT_INFO" | grep -o "charged;")

if [ -z "$PERCENTAGE" ]; then
  sketchybar --set "$NAME" label="" icon.drawing=off
  exit 0
fi

# Build status label
STATUS_LABEL=""
ICON="􀐫"  # Clock icon

if [ -n "$CHARGED" ]; then
  STATUS_LABEL="Fully charged"
  ICON="􀋦"  # Checkmark
elif [ -n "$TIME_REMAINING" ] && [ "$TIME_REMAINING" != "0:00" ]; then
  if [ -n "$CHARGING" ]; then
    STATUS_LABEL="$TIME_REMAINING until full"
  else
    STATUS_LABEL="$TIME_REMAINING remaining"
  fi
elif [ -n "$NO_ESTIMATE" ]; then
  if [ -n "$CHARGING" ]; then
    STATUS_LABEL="Charging..."
  else
    STATUS_LABEL="Calculating..."
  fi
elif [ -n "$CHARGING" ]; then
  STATUS_LABEL="Charging..."
fi

# Update status item
sketchybar --set "$NAME" icon="$ICON" label="$STATUS_LABEL"
