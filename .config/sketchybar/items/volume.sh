#!/bin/bash

source "$CONFIG_DIR/colors.sh"
source "$ITEM_DIR/popup_defaults.sh"

volume=(
	label.drawing=off
	background.drawing=off
	"${POPUP_BACKGROUND[@]}"
	script="$PLUGIN_DIR/sensors/volume.sh"
	click_script="osascript -e 'set volume output muted (not (output muted of (get volume settings)))'; sketchybar --set network popup.drawing=off --set microphone popup.drawing=off"
)

sketchybar --add item volume right \
	--set volume "${volume[@]}" \
	--subscribe volume volume_change mouse.entered mouse.exited \
	\
	--add item volume.level popup.volume \
	--set volume.level \
		"${POPUP_ITEM_DEFAULTS[@]}" \
		icon=􀊧 \
		label="Loading..." \
	\
	--add item volume.device popup.volume \
	--set volume.device \
		"${POPUP_ITEM_DEFAULTS[@]}" \
		icon=􀽆 \
		label="Loading..."

