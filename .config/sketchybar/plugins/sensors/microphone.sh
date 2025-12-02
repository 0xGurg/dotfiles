#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Function to check if microphone is in use
check_microphone() {
  # Check if any app is using the microphone
  MIC_VOLUME=$(osascript -e "input volume of (get volume settings)" 2>/dev/null)
  
  if [ -z "$MIC_VOLUME" ] || [ "$MIC_VOLUME" = "0" ]; then
    # Microphone is muted
    ICON="􀊳"  # Muted microphone icon
    COLOR="$RED"
  else
    # Check if microphone is actively being used
    # This checks if coreaudiod is actively processing input
    if pmset -g | grep -q "coreaudiod" || \
       lsof 2>/dev/null | grep -q "AppleHDAEngineInput" || \
       [ "$MIC_VOLUME" -gt 50 ]; then
      # Microphone is active/in use
      ICON="􂙎"  # Active microphone icon
      COLOR="$GREEN"
    else
      # Microphone is on but not actively in use
      ICON="􀊱"  # Idle microphone icon
      COLOR="$ICON_COLOR"
    fi
  fi
  
  sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR"
}

# Initial check
check_microphone

# Set up periodic checking (every 2 seconds)
if [ "$SENDER" != "forced" ]; then
  sketchybar --set "$NAME" update_freq=2
fi
