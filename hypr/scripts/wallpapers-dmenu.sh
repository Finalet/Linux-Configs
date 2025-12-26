#!/bin/sh

wallpaperFolder="$HOME/.config/hypr/wallpapers"

while [ $# -gt 0 ]; do
  case "$1" in
    --wallpapers-folder)
      shift
      wallpaperFolder="$1"
      ;;
  esac
  shift
done

files=""
for file in "$wallpaperFolder"/*.png; do
    files+="$file\n"
done
files="${files%\\n}"

selected=$(
  printf $files | vicinae dmenu --placeholder "Select wallpaper"
)

"$HOME"/.config/hypr/scripts/change-wallpaper.sh --wallpaper "$selected"