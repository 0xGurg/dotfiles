#!/bin/bash

source "$CONFIG_DIR/colors.sh"
source "$ITEM_DIR/popup_defaults.sh"

microphone=(
	label.drawing=off
	"${POPUP_BACKGROUND[@]}"
	script="$PLUGIN_DIR/sensors/microphone.sh"
	click_script="$PLUGIN_DIR/sensors/microphone.sh toggle; sketchybar --set network popup.drawing=off --set volume popup.drawing=off"
)

set_popup_defaults

sketchybar --add item microphone right \
	--set microphone "${microphone[@]}" \
	--subscribe microphone mouse.entered mouse.exited \
	\
	--add item microphone.device popup.microphone \
	--set microphone.device \
		icon=􀽀 \
		label="Loading..."

