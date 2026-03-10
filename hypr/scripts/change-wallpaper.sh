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

# Update hyprpaper.conf with new wallpaper path using ~ for home
hyprpaperConf="$HOME/.config/hypr/hyprpaper.conf"

# Replace $HOME with ~ in the wallpaper path for config
wallpaperPathForConf="$wallpaperPath"
case "$wallpaperPathForConf" in
  "$HOME"*)
    wallpaperPathForConf="~${wallpaperPathForConf#$HOME}"
    ;;
esac

# Replace only the path value in the existing hyprpaper config
escapedWallpaperPathForConf=$(printf '%s\n' "$wallpaperPathForConf" | sed 's/[\\&]/\\&/g')
sed -i "s|^\([[:space:]]*path[[:space:]]*=[[:space:]]*\).*|\1$escapedWallpaperPathForConf|" "$hyprpaperConf"
echo "Updated path in $hyprpaperConf to new wallpaper."

# Reload wallpaper in Hyprland
hyprctl hyprpaper wallpaper ", $wallpaperPathForConf, cover"
notify-send "Wallpaper changed" "New wallpaper is \"$wallpaperPath\"" -i $wallpaperPath