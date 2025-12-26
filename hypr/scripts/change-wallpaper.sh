#!/bin/sh

# Parse arguments and require --wallpaper
wallpaperPath=""
while [ $# -gt 0 ]; do
  case "$1" in
    --wallpaper)
      shift
      wallpaperPath="$1"
      ;;
  esac
  shift
done

if [ -z "$wallpaperPath" ]; then
  echo "Please provide a wallpaper path using the --wallpaper parameter."
  exit 1
fi

if [ ! -e "$wallpaperPath" ]; then
  echo "There is no wallpaper file under \"$wallpaperPath\". Please add it and try again."
  exit 1
fi

# Reload wallpaper in Hyprland
hyprctl hyprpaper reload , $wallpaperPath
notify-send "Wallpaper changed" "New wallpaper is \"$wallpaperPath\""

# Generate CSS color paller from the new wallpaper using Hellwal
cssOutput="$HOME/.config/hypr/wallpapers/colors.css"
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

# Update hyprpaper.conf with new wallpaper path using ~ for home
hyprpaperConf="$HOME/.config/hypr/hyprpaper.conf"

# Replace $HOME with ~ in the wallpaper path for config
wallpaperPathForConf="$wallpaperPath"
case "$wallpaperPathForConf" in
  "$HOME"*)
    wallpaperPathForConf="~${wallpaperPathForConf#$HOME}"
    ;;
esac

echo "preload = $wallpaperPathForConf" > "$hyprpaperConf"
echo "wallpaper = , $wallpaperPathForConf" >> "$hyprpaperConf"
echo "Updated "$hyprpaperConf" with new wallpaper."