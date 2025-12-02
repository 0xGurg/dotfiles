#!/bin/bash

sketchybar --add item sensors.volume right								\
           --set sensors.volume script="$PLUGIN_DIR/sensors/volume.sh"	\
							   padding_right=8							\
                               label.drawing=off						\
           --subscribe sensors.volume volume_change
