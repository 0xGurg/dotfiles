#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# # This function checks for a connected Bluetooth keyboard.
# is_keyboard_connected() {
# 	if system_profiler SPBluetoothDataType | awk '/Connected:/,/Not Connected:/' | grep -q "Lily58"; then
# 		# SUCCESS (0): grep found "Lily58" in the connected section.
# 		osascript -e 'tell application \"System Events\" to keystroke \" \" using {control down, option down}'
# 		return 0
# 	else
# 		# FAILURE (1): grep did not find "Lily58".
# 		return 1
# 	fi
# }

LAYOUT=$(defaults read ~/Library/Preferences/com.apple.HIToolbox.plist AppleSelectedInputSources | awk '/KeyboardLayout Name/ { sub(/.*= /, ""); sub(/;/, ""); gsub(/"/, ""); print }')
COLOR="$TEXT_COLOR"
# # --- How to use the function ---
# if is_keyboard_connected; then
# 	SHORT_LAYOUT="􀺑" 
# else
# 	# specify short layouts individually
case "$LAYOUT" in
	"Colemak DH Matrix") SHORT_LAYOUT="􀂙" COLOR="$BLUE"; LABEL="Colemak DH";;
	"Dutch") SHORT_LAYOUT="􀂕"; LABEL="Dutch";;
	*) SHORT_LAYOUT="􀫒"; LABEL="$LAYOUT";;
esac
# fi

sketchybar --set "$NAME" icon="$SHORT_LAYOUT" icon.color="$COLOR" label="$LABEL"
