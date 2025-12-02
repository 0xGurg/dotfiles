#!/bin/bash

source "$CONFIG_DIR/colors.sh"
source "$ITEM_DIR/divider.sh"

# Array to track system monitor scripts (sorted by prefix)
monitor_scripts=()

# Find and sort system monitor scripts by their numeric prefix
MONITOR_DIR="$ITEM_DIR/system_monitor"
for monitor_script in $(find "$MONITOR_DIR" -name "*.sh" -type f | sort -V); do
    if [ -f "$monitor_script" ]; then
        monitor_scripts+=("$monitor_script")
    fi
done

# Source scripts and add dividers in reverse order (since we're adding to right)
total=${#monitor_scripts[@]}
for ((i=total-1; i>=0; i--)); do
    # Source the monitor script
    source "${monitor_scripts[$i]}"
    
    # Add divider after each item (except the last one when viewed left-to-right)
    if [ $i -gt 0 ]; then
        add_divider "system_monitor.divider.$i" right
    fi
done

# Create bracket for all system monitor items and dividers using regex pattern
sketchybar --add bracket system_monitor '/system_monitor\..*/' 
