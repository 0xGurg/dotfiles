#!/bin/bash

# Add aerospace workspace change event
sketchybar --add event aerospace_workspace_change

# Function to add a workspace item
add_space_item() {
  local sid=$1
  local display_icon=$2
  
  sketchybar --add item space.$sid left \
    --subscribe space.$sid aerospace_workspace_change \
    --set space.$sid \
      icon="$display_icon" \
      label.font="sketchybar-app-font:Regular:16.0" \
      update_freq=2 \
      script="$PLUGIN_DIR/aerospace.sh $sid" \
      click_script="aerospace workspace $sid"
}

# Create workspace items for 1-5
for sid in $(seq 1 5); do
  add_space_item $sid $sid
done