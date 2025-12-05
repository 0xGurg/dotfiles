#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/helpers/icon_map.sh"

# Get the current focused application name
FRONT_APP=$(aerospace list-windows --focused --format "%{app-name}" 2>/dev/null | head -1)

if [ -n "$FRONT_APP" ]; then
  # Get the icon for the app
  __icon_map "$FRONT_APP"
  APP_ICON="$icon_result"
  
  # Check for SecureInput
  secure_input_enabled=$(ioreg -l -w 0 | grep SecureInput)
  
  if [ -n "$secure_input_enabled" ]; then
    # SecureInput is enabled - add red warning icon
    LABEL="$FRONT_APP 􀞚"
    LABEL_COLOR="$RED"
  else
    # Normal state
    LABEL="$FRONT_APP"
    LABEL_COLOR="$TEXT_COLOR"
  fi
  
  # Set icon and label
  sketchybar --set "$NAME" \
    icon="$APP_ICON" \
    label="$LABEL" \
    label.color="$LABEL_COLOR" \
    drawing=on
else
  sketchybar --set "$NAME" drawing=off
fi
