#!/bin/sh

selected=$(
  printf "→\n←\n↑\n↓\n≠" | vicinae dmenu --placeholder "Select symbol" --no-quick-look
)

[ -n "$selected" ] || exit 0

wl-copy "$selected"
wtype "$selected"


