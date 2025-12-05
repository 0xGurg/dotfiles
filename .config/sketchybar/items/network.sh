#!/bin/bash

source "$CONFIG_DIR/colors.sh"
source "$ITEM_DIR/popup_defaults.sh"

network=(
	icon=􀙇
	label.drawing=off
	background.drawing=off
	"${POPUP_BACKGROUND[@]}"
	update_freq=2
	script="$PLUGIN_DIR/network/network_hover.sh"
)

sketchybar --add item network right \
	--set network "${network[@]}" \
	--subscribe network mouse.entered mouse.exited \
	\
	--add item network.ip popup.network \
	--set network.ip \
		"${POPUP_ITEM_DEFAULTS[@]}" \
		icon=􀵴 \
		label="Loading..." \
		update_freq=5 \
		updates=when_shown \
		script="$PLUGIN_DIR/network/ip.sh" \
	\
	--add item network.router popup.network \
	--set network.router \
		"${POPUP_ITEM_DEFAULTS[@]}" \
		icon=􀌘 \
		label="Loading..." \
		update_freq=10 \
		updates=when_shown \
		script="$PLUGIN_DIR/network/router.sh" \
	\
	--add item network.vpn popup.network \
	--set network.vpn \
		"${POPUP_ITEM_DEFAULTS[@]}" \
		icon=􀞚 \
		label="Loading..." \
		update_freq=5 \
		updates=when_shown \
		script="$PLUGIN_DIR/network/vpn.sh" \
	\
	--add item network.down popup.network \
	--set network.down \
		"${POPUP_ITEM_DEFAULTS[@]}" \
		icon=􀄩 \
		label="Loading..." \
		update_freq=2 \
		updates=when_shown \
		script="$PLUGIN_DIR/network/down.sh" \
	\
	--add item network.up popup.network \
	--set network.up \
		"${POPUP_ITEM_DEFAULTS[@]}" \
		icon=􀄨 \
		label="Loading..." \
		update_freq=2 \
		updates=when_shown \
		script="$PLUGIN_DIR/network/up.sh"

