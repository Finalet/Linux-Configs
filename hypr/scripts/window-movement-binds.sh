#!/bin/bash

# Script that changes move / resize window bind modifier button to from ALT to SUPER for specified classes.

# Check if at least one class is provided
if [[ $# -eq 0 ]]; then
  echo "Usage: $0 <class1> [class2] [class3] ..."
  echo "Example: $0 code figma"
  exit 1
fi

# Store target classes in an array
TARGET_CLASSES=("$@")

# Hyprland socket path
SOCKET_PATH="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"

bind_super() {
  hyprctl keyword unbind alt,mouse:272
  hyprctl keyword unbind alt,mouse:273

  hyprctl keyword bindm super,mouse:272,movewindow
  hyprctl keyword bindm super,mouse:273,resizewindow
}

bind_alt() {
  hyprctl keyword unbind super,mouse:272
  hyprctl keyword unbind super,mouse:273

  hyprctl keyword bindm alt,mouse:272,movewindow
  hyprctl keyword bindm alt,mouse:273,resizewindow
}

# Track current state to avoid redundant calls
current_state=""

# Check if a class matches any target class
is_target_class() {
  local window_class="$1"
  for target in "${TARGET_CLASSES[@]}"; do
    if [[ "$window_class" == "$target" ]]; then
      return 0
    fi
  done
  return 1
}

handle_window_change() {
  local window_class="$1"
  
  if is_target_class "$window_class"; then
    if [[ "$current_state" != "target" ]]; then
      echo "Target window active ($window_class) - binding super key"
      bind_super
      current_state="target"
    fi
  else
    if [[ "$current_state" != "other" ]]; then
      echo "Target window inactive - binding alt key"
      bind_alt
      current_state="other"
    fi
  fi
}

# Set initial state based on current active window
initial_class=$(hyprctl activewindow -j | jq -r '.class // empty')
handle_window_change "$initial_class"

# Listen to activewindow events via socat
socat -U - UNIX-CONNECT:"$SOCKET_PATH" | while read -r line; do
  # activewindow event format:  activewindow>>CLASS,TITLE
  if [[ "$line" == activewindow\>\>* ]]; then
    # Extract window class (everything after >> until the comma)
    window_info="${line#activewindow>>}"
    window_class="${window_info%%,*}"
    
    handle_window_change "$window_class"
  fi
done