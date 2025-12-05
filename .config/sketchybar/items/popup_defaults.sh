#!/bin/bash

# Centralized popup background settings
POPUP_BACKGROUND=(
	popup.background.color="$BG2"
	popup.background.border_width=3
	popup.background.corner_radius=3
	popup.background.border_color="$BORDER_COLOR"
	popup.background.shadow.drawing=on
	popup.background.shadow.color="$SHADOW_COLOR"
	popup.background.shadow.distance=4
	popup.background.shadow.angle=30
	popup.align=center
)

# Array of properties to apply to popup items
POPUP_ITEM_DEFAULTS=(
	icon.font="SF Pro:Semibold:14.0"
	icon.color="$ICON_COLOR"
	label.font="SF Pro:Semibold:13.0"
	background.drawing=off
)
