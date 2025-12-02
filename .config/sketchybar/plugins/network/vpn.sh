#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"

# Check VPN connection status and get IP
VPN_SERVICE=$(scutil --nc list 2>/dev/null | grep "Connected" | head -1)

if [ -n "$VPN_SERVICE" ]; then
  # VPN is connected, try to get VPN IP
  VPN_IF=$(ifconfig 2>/dev/null | grep -B 1 "inet.*10\." | head -1 | awk '{print $1}' | tr -d ':')
  if [ -z "$VPN_IF" ]; then
    VPN_IF=$(ifconfig 2>/dev/null | grep -B 1 "inet.*172\." | head -1 | awk '{print $1}' | tr -d ':')
  fi
  
  if [ -n "$VPN_IF" ]; then
    VPN_IP=$(ifconfig "$VPN_IF" 2>/dev/null | grep "inet " | awk '{print $2}')
    sketchybar --set "$NAME" \
      label="$VPN_IP" \
      label.color=$GREEN
  else
    sketchybar --set "$NAME" \
      label="Connected" \
      label.color=$GREEN
  fi
else
  sketchybar --set "$NAME" \
    label="Not connected" \
    label.color=$TEXT_COLOR2
fi
