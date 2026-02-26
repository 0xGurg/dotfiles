#!/bin/bash
# nvhc - Open Neovim alongside Cursor in a split layout
#
# This script:
# 1. Quits Cursor if running
# 2. Opens Cursor in the current directory
# 3. Sends Cmd+Opt+E to Cursor (toggle sidebar or similar)
# 4. Focuses Ghostty terminal
# 5. Resizes the window and opens Neovim

# Quit Cursor if running
osascript -e 'tell application "Cursor" to quit' 2>/dev/null

sleep 1

# Open Cursor in current directory
cursor .

sleep 2

# Activate Cursor and send keystroke
osascript -e 'tell application "Cursor" to activate'
osascript -e 'tell application "System Events" to keystroke "e" using {command down, option down}'

sleep 1

# Focus Ghostty window via AeroSpace
ghostty_window_id=$(aerospace list-windows --all --format "%{app-name} %{window-id}" | grep -i ghostty | head -1 | awk '{print $2}')
if [[ -n "$ghostty_window_id" ]]; then
  aerospace focus --window-id "$ghostty_window_id"
fi

# Resize and open Neovim
aerospace resize smart +300
nvim .
