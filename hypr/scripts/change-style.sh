#!/bin/sh

STYLE_FILE=${STYLE_FILE:-"$HOME/.config/hypr/configs/styles.conf"}

apply_style() {
  # args arrive as key value pairs
  if [ $(( $# % 2 )) -ne 0 ]; then
    echo "Style application needs key/value pairs" >&2
    exit 1
  fi

  if [ ! -f "$STYLE_FILE" ]; then
    echo "Config file missing: $STYLE_FILE" >&2
    exit 1
  fi

  sed_script=""
  while [ $# -gt 0 ]; do
    key=$1
    value=$2
    shift 2
    sed_script="${sed_script}s/^([[:space:]]*${key}[[:space:]]*=[[:space:]]*).*/\\1${value}/;"
  done

  # shellcheck disable=SC2001 # sed_script is intentionally constructed for sed -E
  sed -E -i "$sed_script" "$STYLE_FILE"
}

SetStyleCompact() {
  apply_style \
    border_size 0 \
    gaps_in 0 \
    gaps_out 0 \
    rounding 0 \
    rounding_power 2 \
    active_opacity 1 \
    inactive_opacity 0.9
}

SetStyleDefault() {
  apply_style \
    border_size 2 \
    gaps_in 0 \
    gaps_out 0 \
    rounding 10 \
    rounding_power 2 \
    active_opacity 0.9 \
    inactive_opacity 0.9
}

SetStyleBubbly() {
  apply_style \
    border_size 2 \
    gaps_in 2 \
    gaps_out 2 \
    rounding 18 \
    rounding_power 3 \
    active_opacity 0.9 \
    inactive_opacity 0.9
}

selectedStyle=$(
  printf "Compact\nDefault\nBubbly" | vicinae dmenu --placeholder "Select style" --no-quick-look
)

case "$selectedStyle" in
  Default) SetStyleDefault ;;
  Compact) SetStyleCompact ;;
  Bubbly) SetStyleBubbly ;;
esac