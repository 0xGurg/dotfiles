#!/bin/bash

calendar=(
	icon=􀧞
	padding_left=10
	padding_right=0
	update_freq=1		
	script="$PLUGIN_DIR/calendar.sh"
)

sketchybar --add item calendar right	\
	--set calendar "${calendar[@]}"		\
