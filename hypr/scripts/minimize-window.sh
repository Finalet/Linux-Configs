#!/usr/bin/env bash

if [[ -z $(hyprctl workspaces | grep special:minimizedWindow) ]]; then
    hyprctl dispatch movetoworkspacesilent special:minimizedWindow
else
    hyprctl --batch 'dispatch togglespecialworkspace minimizedWindow;dispatch movetoworkspace +0'
fi