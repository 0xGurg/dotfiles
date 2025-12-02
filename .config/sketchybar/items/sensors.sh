#!/bin/bash

source "$CONFIG_DIR/colors.sh"
source "$ITEM_DIR/divider.sh"

# Array to track sensor scripts (sorted by prefix)
sensor_scripts=()

# Find and sort sensor scripts by their numeric prefix
SENSOR_DIR="$ITEM_DIR/sensors"
for sensor_script in $(find "$SENSOR_DIR" -name "*.sh" -type f | sort -V); do
    if [ -f "$sensor_script" ]; then
        sensor_scripts+=("$sensor_script")
    fi
done

# Source scripts and add dividers in reverse order (since we're adding to right)
total=${#sensor_scripts[@]}
for ((i=total-1; i>=0; i--)); do
    # Source the sensor script
    source "${sensor_scripts[$i]}"
    
    # Add divider after each sensor (except the last one when viewed left-to-right)
    if [ $i -gt 0 ]; then
        add_divider "sensors.divider.$i" right
    fi
done

# Create bracket for all sensor items and dividers using regex pattern
sketchybar --add bracket sensors '/sensors\..*/'
