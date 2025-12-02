#!/bin/bash

source "$CONFIG_DIR/colors.sh"

divider=(
	width=2 
	padding_left=4
	padding_right=4
	icon.drawing=off 
	label.drawing=off 
	background.height=15 
	background.corner_radius=1 
	background.color=$TEXT_COLOR2 
)

# Function to add a divider
add_divider() {
    local name="$1"
    local position="${2:-right}"
    
    sketchybar --add item "$name" "$position"	\
               --set "$name" "${divider[@]}"
}
