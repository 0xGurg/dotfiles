#!/bin/bash

source "$CONFIG_DIR/colors.sh"
source "$ITEM_DIR/popup_defaults.sh"

volume=(
	label.drawing=off
	padding_right=8
	popup.align=center
	"${POPUP_BACKGROUND[@]}"
	script="$PLUGIN_DIR/sensors/volume.sh"
	click_script="osascript -e 'set volume output muted (not (output muted of (get volume settings)))'; sketchybar --set network popup.drawing=off --set microphone popup.drawing=off"
)

set_popup_defaults

sketchybar --add item volume right \
	--set volume "${volume[@]}" \
	--subscribe volume volume_change mouse.entered mouse.exited \
	\
	--add item volume.level popup.volume \
	--set volume.level \
		icon=􀊧 \
		label="Loading..." \
	\
	--add item volume.device popup.volume \
	--set volume.device \
		icon=􀽆 \
		label="Loading..."

