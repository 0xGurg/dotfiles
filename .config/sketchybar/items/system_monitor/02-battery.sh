#!/bin/bash

source "$CONFIG_DIR/colors.sh"
source "$ITEM_DIR/popup_defaults.sh"

battery=(
	icon.font="SF Pro:Semibold:16.0"
	label.drawing=off
	update_freq=120
	"${POPUP_BACKGROUND[@]}"
	script="$PLUGIN_DIR/battery/battery.sh"
)

# Set defaults for popup items
set_popup_defaults

sketchybar --add item system_monitor.battery right \
	--set system_monitor.battery "${battery[@]}" \
	--subscribe system_monitor.battery system_woke power_source_change mouse.entered mouse.exited \
	\
	--add item system_monitor.battery.percentage popup.system_monitor.battery \
	--set system_monitor.battery.percentage \
		icon=􀖇 \
		label="Loading..." \
		update_freq=30 \
		script="$PLUGIN_DIR/battery/percentage.sh" \
	\
	--add item system_monitor.battery.status popup.system_monitor.battery \
	--set system_monitor.battery.status \
		icon=􀖇 \
		label="..." \
		update_freq=30 \
		script="$PLUGIN_DIR/battery/status.sh" \
	\
	--add item system_monitor.battery.cpu popup.system_monitor.battery \
	--set system_monitor.battery.cpu \
		icon=􀧓 \
		label="N/A" \
		update_freq=2 \
		script="$PLUGIN_DIR/battery/cpu.sh" \
	\
	--add item system_monitor.battery.ram popup.system_monitor.battery \
	--set system_monitor.battery.ram \
		icon=􀧖 \
		label="N/A" \
		update_freq=2 \
		script="$PLUGIN_DIR/battery/ram.sh" \
	\
	--add item system_monitor.battery.disk popup.system_monitor.battery \
	--set system_monitor.battery.disk \
		icon=􀨪 \
		label="N/A" \
		update_freq=10 \
		script="$PLUGIN_DIR/battery/disk.sh" \
	\
	--add item system_monitor.battery.temp popup.system_monitor.battery \
	--set system_monitor.battery.temp \
		icon=􀇬 \
		icon.padding_left=8 \
		label="N/A" \
		update_freq=5 \
		script="$PLUGIN_DIR/battery/temp.sh"
