#!/bin/bash

source "$CONFIG_DIR/colors.sh"

is_muted() {
  MIC_VOLUME=$(osascript -e "input volume of (get volume settings)" 2>/dev/null)
  [ -z "$MIC_VOLUME" ] || [ "$MIC_VOLUME" = "0" ]
}

update_icon() {
  if is_muted; then
    sketchybar --set microphone icon="􀊳" icon.color="$RED"
  else
    sketchybar --set microphone icon="􀊱" icon.color="$ICON_COLOR"
  fi
}

update_popup() {
  if command -v SwitchAudioSource &> /dev/null; then
    INPUT_DEVICE=$(SwitchAudioSource -t input -c 2>/dev/null)
  fi
  [ -z "$INPUT_DEVICE" ] && INPUT_DEVICE="Audio Input"

  sketchybar --set microphone.device label="$INPUT_DEVICE"
}

# Handle toggle command (called from click_script)
if [ "$1" = "toggle" ]; then
  if is_muted; then
    osascript -e "set volume input volume 100"
  else
    osascript -e "set volume input volume 0"
  fi
  update_icon
  exit 0
fi

case "$SENDER" in
  "mouse.entered")
    update_popup
    sketchybar --set microphone popup.drawing=on
    ;;
  "mouse.exited")
    sketchybar --set microphone popup.drawing=off
    ;;
  *)
    update_icon
    ;;
esac
