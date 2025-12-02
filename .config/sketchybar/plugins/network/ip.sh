#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"

# Get IP Address
IP_ADDRESS=$(ipconfig getifaddr en0 2>/dev/null)

if [ -z "$IP_ADDRESS" ]; then
  IP_ADDRESS="N/A"
fi

sketchybar --set "$NAME" label="$IP_ADDRESS"
