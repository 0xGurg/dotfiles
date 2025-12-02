#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"

BATT_INFO=$(pmset -g batt)
PERCENTAGE=$(echo "$BATT_INFO" | grep -Eo "\d+%" | cut -d% -f1)
CHARGING=$(echo "$BATT_INFO" | grep 'AC Power')

# Get time remaining, filtering out unwanted text
TIME_REMAINING=$(echo "$BATT_INFO" | grep -o "[0-9]\+:[0-9]\+" | head -1)

if [ -z "$PERCENTAGE" ]; then
  sketchybar --set "$NAME" label=""
  exit 0
fi

# Build status label
STATUS_LABEL=""
if [ -n "$TIME_REMAINING" ] && [ "$TIME_REMAINING" != "0:00" ]; then
  if [ -n "$CHARGING" ]; then
    STATUS_LABEL="Charging ($TIME_REMAINING)"
  else
    STATUS_LABEL="$TIME_REMAINING remaining"
  fi
elif [ -n "$CHARGING" ] && [ "$PERCENTAGE" -ge 95 ]; then
  STATUS_LABEL="Fully charged"
fi

# Update status item
sketchybar --set "$NAME" label="$STATUS_LABEL"
