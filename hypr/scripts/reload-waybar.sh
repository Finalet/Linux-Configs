#!/bin/sh

# 1️⃣ Path to wallpaper
WALLPAPER="$1"
if [ -z "$WALLPAPER" ]; then
    echo "Usage: $0 /path/to/wallpaper.jpg"
    exit 1
fi

# 2️⃣ Output CSS file for Waybar using @define-color
OUT="$HOME/.config/hypr/wallpaper/colors.css"

# Generate CSS directly from Hellwal JSON without saving JSON file
hellwal -i "$WALLPAPER" --json | jq -r '
  # Define special colors
  "@define-color background " + .special.background + ";",
  "@define-color foreground " + .special.foreground + ";",
  "@define-color cursor "     + .special.cursor + ";",
  "@define-color border "     + .special.border + ";",
  # Define palette colors
  (.colors | to_entries[] | "@define-color " + .key + " " + .value + ";")
' > "$OUT"

echo "Waybar colors updated from wallpaper: $WALLPAPER"

killall waybar
waybar & disown