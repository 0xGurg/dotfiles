#!/bin/bash

source "$CONFIG_DIR/colors.sh"
source "$ITEM_DIR/popup_defaults.sh"

network=(
	icon=􀙇
	icon.font="SF Pro:Semibold:16.0"
	label.drawing=off
	"${POPUP_BACKGROUND[@]}"
	update_freq=3
	script="$PLUGIN_DIR/network/network_hover.sh"
)

# Set defaults for popup items
set_popup_defaults

sketchybar --add item system_monitor.network right \
	--set system_monitor.network "${network[@]}" \
	--subscribe system_monitor.network mouse.entered mouse.exited \
	\
	--add item system_monitor.network.ip popup.system_monitor.network \
	--set system_monitor.network.ip \
		icon=􀵴 \
		label="Loading..." \
		update_freq=5 \
		script="$PLUGIN_DIR/network/ip.sh" \
	\
	--add item system_monitor.network.router popup.system_monitor.network \
	--set system_monitor.network.router \
		icon=􀌘 \
		label="Loading..." \
		update_freq=10 \
		script="$PLUGIN_DIR/network/router.sh" \
	\
	--add item system_monitor.network.vpn popup.system_monitor.network \
	--set system_monitor.network.vpn \
		icon=􀞚 \
		label="Loading..." \
		update_freq=5 \
		script="$PLUGIN_DIR/network/vpn.sh" \
	\
	--add item system_monitor.network.down popup.system_monitor.network \
	--set system_monitor.network.down \
		icon=􀄩 \
		label="Loading..." \
		update_freq=2 \
		script="$PLUGIN_DIR/network/down.sh" \
	\
	--add item system_monitor.network.up popup.system_monitor.network \
	--set system_monitor.network.up \
		icon=􀄨 \
		label="Loading..." \
		update_freq=2 \
		script="$PLUGIN_DIR/network/up.sh"
