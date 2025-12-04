#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Handle hover events
case "$SENDER" in
  "mouse.entered")
    sketchybar --set battery popup.drawing=on \
               --set network popup.drawing=off
    exit 0
    ;;
  "mouse.exited")
    sketchybar --set battery popup.drawing=off
    exit 0
    ;;
esac

PERCENTAGE="$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)"
CHARGING="$(pmset -g batt | grep 'AC Power')"

if [ "$PERCENTAGE" = "" ]; then
  exit 0
fi

case "${PERCENTAGE}" in
9[0-9] | 100) ICON="􀛨" COLOR="$ICON_COLOR";;
[6-8][0-9]) ICON="􀺸" COLOR="$GREEN" ;;
[3-5][0-9]) ICON="􀺶" COLOR="$YELLOW" ;;
[1-2][0-9]) ICON="􀛩" COLOR="$ORANGE" ;;
*) ICON="􀛪" COLOR="$RED" ;;
esac

if [[ "$CHARGING" != "" ]]; then
  ICON="􀢋" COLOR="$BLUE"
fi

# The item invoking this script (name $NAME) will get its icon
# updated with the current battery status

sketchybar --set "$NAME" icon="$ICON" icon.color="${COLOR}"
