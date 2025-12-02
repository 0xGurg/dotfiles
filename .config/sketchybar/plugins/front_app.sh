#!/usr/bin/env bash

# Source the icon map
source "$CONFIG_DIR/helpers/icon_map.sh"

# Get the current focused application name
FRONT_APP=$(aerospace list-windows --focused --format "%{app-name}" 2>/dev/null | head -1)

if [ -n "$FRONT_APP" ]; then
  # Get the icon for the app
  __icon_map "$FRONT_APP"
  APP_ICON="$icon_result"
  
  # Set icon and label separately
  sketchybar --set "$NAME" \
    icon="$APP_ICON" \
    label="$FRONT_APP" \
    drawing=on
else
  sketchybar --set "$NAME" drawing=off
fi
