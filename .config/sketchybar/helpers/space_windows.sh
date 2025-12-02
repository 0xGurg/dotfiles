#!/usr/bin/env bash

# Source the icon map
source "$CONFIG_DIR/helpers/icon_map.sh"

# Get the workspace ID from the argument
WORKSPACE_ID=$1

# Get windows for the workspace
if [ "$WORKSPACE_ID" = "other" ]; then
  # For "other", get all workspaces beyond 4
  WINDOWS=$(aerospace list-windows --workspace 5 --workspace 6 --workspace 7 --workspace 8 --workspace 9 --format "%{app-name}" 2>/dev/null | head -3)
else
  # For specific workspaces
  WINDOWS=$(aerospace list-windows --workspace "$WORKSPACE_ID" --format "%{app-name}" 2>/dev/null | head -3)
fi

# Build the icon string
ICON_STRING=""
if [ -n "$WINDOWS" ]; then
  while IFS= read -r app; do
    if [ -n "$app" ]; then
      __icon_map "$app"
      ICON_STRING+="$icon_result "
    fi
  done <<< "$WINDOWS"
fi

# Remove trailing space
ICON_STRING=$(echo "$ICON_STRING" | sed 's/ *$//')

echo "$ICON_STRING"

