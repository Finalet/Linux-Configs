#!/bin/sh

if yad --question \
  --title="Shutdown" \
  --text="Are you sure you want to shut down this computer?" \
  --image="system-shutdown" \
  --borders=20 \
  --window-type=dialog \
  --fixed; then
  hyprhalt --text "Shutting down" --post-cmd 'shutdown -P now'
    # hyprshutdown --post-cmd 'shutdown -P now'
fi