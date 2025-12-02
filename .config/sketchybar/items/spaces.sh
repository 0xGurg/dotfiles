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
      icon.padding_left=8 \
      icon.padding_right=4 \
      icon.y_offset=0 \
      label.font="sketchybar-app-font:Regular:16.0" \
      label.padding_left=4 \
      label.padding_right=8 \
      label.y_offset=0 \
      update_freq=2 \
      script="$PLUGIN_DIR/aerospace.sh $sid" \
      click_script="aerospace workspace $sid"
}

# Create workspace items for 1-5
for sid in $(seq 1 5); do
  add_space_item $sid $sid
done

# Space 1 should have no left padding (it's the first item)
sketchybar --set space.1 padding_left=0

