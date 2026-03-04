#!/bin/sh

if yad --question \
  --title="Logout" \
  --text="Are you sure you want to log out of this session?" \
  --image="system-log-out" \
  --borders=20 \
  --window-type=dialog \
  --fixed; then
  hyprhalt --text "Logging out" --post-cmd 'hyprctl dispatch exit'
fi