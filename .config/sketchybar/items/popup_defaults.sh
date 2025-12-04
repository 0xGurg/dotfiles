#!/bin/bash

# Centralized popup background settings
POPUP_BACKGROUND=(
	popup.background.color="$BG2"
	popup.background.border_width=2
	popup.background.corner_radius=5
	popup.background.border_color="$ICON_COLOR"
	popup.align=center
)

# Function to set defaults for popup items
set_popup_defaults() {
	sketchybar --default \
		icon.font="SF Pro:Semibold:14.0" \
		icon.color="$ICON_COLOR" \
		label.font="SF Pro:Semibold:13.0" \
		background.padding_left=5 \
		background.padding_right=5
}
