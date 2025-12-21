#!/bin/sh

wallpaperPath="$HOME/.config/hypr/wallpaper/wallpaper.png"
if [ ! -e "$wallpaperPath" ]; then
  echo "There is no wallpaper file under \"$wallpaperPath\". Please add it and try again."
  exit 1
fi

# Reload wallpaper in Hyprland
hyprctl hyprpaper reload , $wallpaperPath
echo "Hyprland wallpaper set to \"$wallpaperPath\""

# Generate CSS color paller from the new wallpaper using Hellwal
cssOutput="$HOME/.config/hypr/wallpaper/colors.css"
hellwal -i "$wallpaperPath" --json --no-cache | jq -r '
  # Define special colors
  "@define-color background " + .special.background + ";",
  "@define-color foreground " + .special.foreground + ";",
  "@define-color cursor "     + .special.cursor + ";",
  "@define-color border "     + .special.border + ";",
  # Define palette colors
  (.colors | to_entries[] | "@define-color " + .key + " " + .value + ";")
' > "$cssOutput"

echo "Generated CSS color palette at \"$cssOutput\""

# Reload Waybar that relies on generated CSS colors
killall waybar
waybar & disown

