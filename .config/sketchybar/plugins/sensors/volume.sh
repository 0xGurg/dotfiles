#!/bin/bash

source "$CONFIG_DIR/colors.sh"

update_icon() {
  VOLUME=$(osascript -e "output volume of (get volume settings)")
  MUTED=$(osascript -e "output muted of (get volume settings)")

  COLOR=$ICON_COLOR

  if [ "$MUTED" = "true" ]; then
    ICON="􀊣"
    COLOR="$RED"
  else
    case "$VOLUME" in
      [6-9][0-9]|100) ICON="􀊩";;
      [3-5][0-9]) ICON="􀊧";;
      [1-9]|[1-2][0-9]) ICON="􀊥";;
      *) ICON="􀊣" COLOR="$RED";;
    esac
  fi

  sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR"
}

update_popup() {
  VOLUME=$(osascript -e "output volume of (get volume settings)" 2>/dev/null)
  MUTED=$(osascript -e "output muted of (get volume settings)" 2>/dev/null)

  if [ "$MUTED" = "true" ]; then
    VOL_ICON="􀊣"
    VOL_COLOR="$RED"
    VOL_LABEL="Muted"
  else
    VOL_LABEL="${VOLUME}%"
    VOL_COLOR="$ICON_COLOR"
    case "$VOLUME" in
      [6-9][0-9]|100) VOL_ICON="􀊩";;
      [3-5][0-9]) VOL_ICON="􀊧";;
      [1-9]|[1-2][0-9]) VOL_ICON="􀊥";;
      *) VOL_ICON="􀊣";;
    esac
  fi

  if command -v SwitchAudioSource &> /dev/null; then
    OUTPUT_DEVICE=$(SwitchAudioSource -c 2>/dev/null)
  fi
  [ -z "$OUTPUT_DEVICE" ] && OUTPUT_DEVICE="Audio Output"

  sketchybar --set volume.level icon="$VOL_ICON" icon.color="$VOL_COLOR" label="$VOL_LABEL" \
             --set volume.device label="$OUTPUT_DEVICE"
}

case "$SENDER" in
  "mouse.entered")
    update_popup
    sketchybar --set volume popup.drawing=on
    ;;
  "mouse.exited")
    sketchybar --set volume popup.drawing=off
    ;;
  *)
    update_icon
    ;;
esac
