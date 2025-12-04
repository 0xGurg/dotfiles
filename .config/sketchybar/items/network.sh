#!/bin/bash

source "$CONFIG_DIR/colors.sh"
source "$ITEM_DIR/popup_defaults.sh"

network=(
	icon=􀙇
	label.drawing=off
	"${POPUP_BACKGROUND[@]}"
	update_freq=2
	script="$PLUGIN_DIR/network/network_hover.sh"
)

set_popup_defaults

sketchybar --add item network right \
	--set network "${network[@]}" \
	--subscribe network mouse.entered mouse.exited \
	\
	--add item network.ip popup.network \
	--set network.ip \
		icon=􀵴 \
		label="Loading..." \
		update_freq=5 \
		script="$PLUGIN_DIR/network/ip.sh" \
	\
	--add item network.router popup.network \
	--set network.router \
		icon=􀌘 \
		label="Loading..." \
		update_freq=10 \
		script="$PLUGIN_DIR/network/router.sh" \
	\
	--add item network.vpn popup.network \
	--set network.vpn \
		icon=􀞚 \
		label="Loading..." \
		update_freq=5 \
		script="$PLUGIN_DIR/network/vpn.sh" \
	\
	--add item network.down popup.network \
	--set network.down \
		icon=􀄩 \
		label="Loading..." \
		update_freq=2 \
		script="$PLUGIN_DIR/network/down.sh" \
	\
	--add item network.up popup.network \
	--set network.up \
		icon=􀄨 \
		label="Loading..." \
		update_freq=2 \
		script="$PLUGIN_DIR/network/up.sh"

