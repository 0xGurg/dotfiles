#!/bin/bash

sketchybar --add item sensors.microphone right							\
           --set sensors.microphone script="$PLUGIN_DIR/sensors/microphone.sh"	\
								   padding_left=0 \
								   label.drawing=off           
