#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"

update_network_main() {
  # Get Ethernet interface
  ETHERNET_DEVICE=$(networksetup -listallhardwareports | awk '/Ethernet/{getline; print $2}' | head -1)
  
  # Check if Ethernet is connected
  ETHERNET_CONNECTED=false
  if [ -n "$ETHERNET_DEVICE" ]; then
    ETHERNET_STATUS=$(ifconfig "$ETHERNET_DEVICE" 2>/dev/null | grep "status: active")
    if [ -n "$ETHERNET_STATUS" ]; then
      ETHERNET_CONNECTED=true
    fi
  fi

  # If Ethernet is connected, show Ethernet icon
  if [ "$ETHERNET_CONNECTED" = true ]; then
    sketchybar --set network \
      icon=􀶿 \
      icon.color=$ICON_COLOR \
      drawing=on
    return
  fi

  # Get WiFi interface
  WIFI_DEVICE=$(networksetup -listallhardwareports | awk '/Wi-Fi|AirPort/{getline; print $2}' | head -1)

  # Try multiple methods to get SSID
  if [ -n "$WIFI_DEVICE" ]; then
    # Method 1: Try ifconfig parsing
    SSID=$(ifconfig "$WIFI_DEVICE" 2>/dev/null | grep -o "SSID: .*" | sed 's/SSID: //' | sed 's/ //')
    
    # Method 2: Try networksetup with grep to avoid redaction message
    if [ -z "$SSID" ]; then
      NETWORK_INFO=$(networksetup -getairportnetwork "$WIFI_DEVICE" 2>/dev/null)
      if echo "$NETWORK_INFO" | grep -q "Current Wi-Fi Network:"; then
        SSID=$(echo "$NETWORK_INFO" | awk -F': ' '{print $2}')
      fi
    fi
    
    # Method 3: Check if connected at all via ifconfig status
    if [ -z "$SSID" ]; then
      STATUS=$(ifconfig "$WIFI_DEVICE" 2>/dev/null | grep "status: active")
      if [ -n "$STATUS" ]; then
        SSID="Connected"
      fi
    fi
  fi

  if [ -n "$SSID" ] && [ "$SSID" != "You are not associated with an AirPort network." ] && [ "$SSID" != "<redacted>" ]; then
    # WiFi is connected - show normal WiFi icon in ICON_COLOR
    sketchybar --set network \
      icon=􀙇 \
      icon.color=$ICON_COLOR \
      drawing=on
  else
    # No connection - show slash icon in red
    sketchybar --set network \
      icon=􀙈 \
      icon.color=$RED \
      drawing=on
  fi
}

case "$SENDER" in
  "mouse.entered")
    sketchybar --set network popup.drawing=on
    ;;
  "mouse.exited")
    sketchybar --set network popup.drawing=off
    ;;
  "routine")
    update_network_main
    ;;
esac
