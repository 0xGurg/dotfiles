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

# Function to check app notification status
check_app_notifications() {
  local app_name="$1"
  local status_label=$(lsappinfo info -only StatusLabel "$app_name" 2>/dev/null)
  
  if [[ $status_label =~ \"label\"=\"([^\"]*)\" ]]; then
    local label="${BASH_REMATCH[1]}"
    if [[ $label =~ ^[0-9]+$ ]]; then
      echo "count"
    elif [[ $label == "•" ]]; then
      echo "activity"
    else
      echo "none"
    fi
  else
    echo "none"
  fi
}

# Get list of apps in this workspace
WORKSPACE_APPS=$(aerospace list-windows --workspace "$WORKSPACE_ID" --format "%{app-name}" 2>/dev/null)

# Apps to check for notifications
NOTIFICATION_APPS=("Slack" "Microsoft Teams" "WhatsApp")

# Determine notification status
NOTIFICATION_STATUS="none"
for app in "${NOTIFICATION_APPS[@]}"; do
  # Check if this app is in the workspace
  if echo "$WORKSPACE_APPS" | grep -q "^${app}$"; then
    STATUS=$(check_app_notifications "$app")
    
    # Priority: count > activity > none
    if [ "$STATUS" = "count" ]; then
      NOTIFICATION_STATUS="count"
      break  # Highest priority, no need to check others
    elif [ "$STATUS" = "activity" ] && [ "$NOTIFICATION_STATUS" != "count" ]; then
      NOTIFICATION_STATUS="activity"
    fi
  fi
done

# Set border color based on notification status
BORDER_COLOR_VAL=$BORDER_COLOR
if [ "$NOTIFICATION_STATUS" = "count" ]; then
  BORDER_COLOR_VAL=$RED
elif [ "$NOTIFICATION_STATUS" = "activity" ]; then
  BORDER_COLOR_VAL=$YELLOW
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
      label="$DISPLAY_LABEL" \
      background.border_color=$BORDER_COLOR_VAL
  else
    sketchybar --set "$NAME" \
      drawing=on \
      icon.color=$TEXT_COLOR \
      label.color=$TEXT_COLOR \
      label="$DISPLAY_LABEL" \
      background.border_color=$BORDER_COLOR_VAL
  fi
fi

