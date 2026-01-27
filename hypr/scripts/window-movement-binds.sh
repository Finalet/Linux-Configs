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

MOD_MASK_SUPER=64
MOD_MASK_ALT=8

bind_super() {
  hyprctl keyword unbind alt,mouse:272 >/dev/null
  hyprctl keyword unbind alt,mouse:273 >/dev/null

  hyprctl keyword bindm super,mouse:272,movewindow >/dev/null
  hyprctl keyword bindm super,mouse:273,resizewindow >/dev/null
}

bind_alt() {
  hyprctl keyword unbind super,mouse:272 >/dev/null
  hyprctl keyword unbind super,mouse:273 >/dev/null

  hyprctl keyword bindm alt,mouse:272,movewindow >/dev/null
  hyprctl keyword bindm alt,mouse:273,resizewindow >/dev/null
}

get_keybind_modmask() {
  local target_key="$1"

  if [[ -z "$target_key" ]]; then
    echo "Usage: get_keybind_modmask <key>" >&2
    return 1
  fi

  local modmask
  modmask=$(hyprctl binds -j | jq -r --arg key "$target_key" '.[] | select(.key == $key) | .modmask' | head -n 1)

  if [[ -z "$modmask" || "$modmask" == "null" ]]; then
    return 1
  fi

  echo "$modmask"
}

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
  local current_modmask=$(get_keybind_modmask "mouse:272")
  
  if is_target_class "$window_class"; then
    if [[ "$current_modmask" != "$MOD_MASK_SUPER" ]]; then
      echo "Target window active ($window_class) - binding SUPER key"
      bind_super
    fi
    echo "Target window active ($window_class) - SUPER key is already binded"
  else
    if [[ "$current_modmask" != "$MOD_MASK_ALT" ]]; then
      echo "Target window inactive - binding ALT key"
      bind_alt
    fi
    echo "Target window inactive - ALT key is already binded"
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