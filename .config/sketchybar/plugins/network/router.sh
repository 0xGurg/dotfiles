#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"

# Get router/gateway IP
ROUTER=$(netstat -nr | grep default | grep -v ":" | awk '{print $2}' | head -1)

if [ -z "$ROUTER" ]; then
  ROUTER="No Gateway"
fi

sketchybar --set "$NAME" label="$ROUTER"
