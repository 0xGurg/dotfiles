#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"

WORKSPACE_ID=$1

# Get the current focused workspace if not provided by event
if [ -z "$FOCUSED_WORKSPACE" ]; then
  FOCUSED_WORKSPACE=$(aerospace list-workspaces --focused)
fi

# Check specific workspace
WINDOW_COUNT=$(aerospace list-windows --workspace "$WORKSPACE_ID" 2>/dev/null | wc -l | tr -d ' ')

# Get app icons for this workspace
APP_ICONS=$("$CONFIG_DIR/helpers/space_windows.sh" "$WORKSPACE_ID")

# Determine if this is the focused workspace
IS_FOCUSED=false
if [ "$WORKSPACE_ID" = "$FOCUSED_WORKSPACE" ]; then
  IS_FOCUSED=true
fi

# For workspaces 1-5, always show them
if [[ "$WORKSPACE_ID" =~ ^[1-5]$ ]]; then
  # Show em dash if empty, otherwise show app icons
  if [ -z "$APP_ICONS" ]; then
    DISPLAY_LABEL="—"
  else
    DISPLAY_LABEL="$APP_ICONS"
  fi
  
  if [ "$IS_FOCUSED" = true ]; then
    sketchybar --set "$NAME" \
      drawing=on \
      icon.color=$ICON_COLOR \
      label.color=$ICON_COLOR \
      label="$DISPLAY_LABEL"
  else
    sketchybar --set "$NAME" \
      drawing=on \
      icon.color=$TEXT_COLOR \
      label.color=$TEXT_COLOR \
      label="$DISPLAY_LABEL"
  fi
fi

