#!/bin/sh

if zenity --question --text="Are you sure you want to shut down?" --icon="computer" --title="Shutdown"; then
    hyprshutdown --post-cmd 'shutdown -P 0'
fi

