#!/bin/bash

source "$CONFIG_DIR/colors.sh"
source "$ITEM_DIR/popup_defaults.sh"

battery=(
	label.drawing=off
	update_freq=120
	"${POPUP_BACKGROUND[@]}"
	script="$PLUGIN_DIR/battery/battery.sh"
)

set_popup_defaults

sketchybar --add item battery right \
	--set battery "${battery[@]}" \
	--subscribe battery system_woke power_source_change mouse.entered mouse.exited \
	\
	--add item battery.percentage popup.battery \
	--set battery.percentage \
		icon=􀖇 \
		label="Loading..." \
		update_freq=30 \
		script="$PLUGIN_DIR/battery/percentage.sh" \
	\
	--add item battery.status popup.battery \
	--set battery.status \
		icon=􀐫 \
		label="..." \
		update_freq=30 \
		script="$PLUGIN_DIR/battery/status.sh" \
	\
	--add item battery.cpu popup.battery \
	--set battery.cpu \
		icon=􀧓 \
		label="N/A" \
		update_freq=2 \
		script="$PLUGIN_DIR/battery/cpu.sh" \
	\
	--add item battery.ram popup.battery \
	--set battery.ram \
		icon=􀧖 \
		label="N/A" \
		update_freq=2 \
		script="$PLUGIN_DIR/battery/ram.sh" \
	\
	--add item battery.disk popup.battery \
	--set battery.disk \
		icon=􀨪 \
		label="N/A" \
		update_freq=10 \
		script="$PLUGIN_DIR/battery/disk.sh" \
	\
	--add item battery.temp popup.battery \
	--set battery.temp \
		icon=􀇬 \
		icon.padding_left=8 \
		label="N/A" \
		update_freq=5 \
		script="$PLUGIN_DIR/battery/temp.sh"

