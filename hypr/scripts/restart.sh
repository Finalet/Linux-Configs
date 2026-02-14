#!/bin/sh

if yad --question \
  --title="Restart" \
  --text="Are you sure you want to restart this computer?" \
  --image="system-restart" \
  --borders=20 \
  --window-type=dialog \
  --fixed; then
    hyprshutdown --post-cmd 'shutdown -r now'
fi