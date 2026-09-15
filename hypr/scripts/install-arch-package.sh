#!/bin/sh

selected_packages=$(yay -Sl |
  fzf --multi \
    --preview 'yay -Sii {1}/{2}' \
    --preview-label='alt-p: toggle description, alt-b/B: toggle PKGBUILD, alt-j/k: scroll, tab: multi-select' \
    --preview-label-pos=bottom \
    --preview-window='down:65%:wrap' \
    --bind='alt-p:toggle-preview' \
    --bind='alt-d:preview-half-page-down,alt-u:preview-half-page-up' \
    --bind='alt-k:preview-up,alt-j:preview-down' \
    --bind='alt-b:change-preview:if [ {1} = aur ]; then yay -Gpa {2}; else yay -Gp {1}/{2}; fi' \
    --bind='alt-B:change-preview:yay -Sii {1}/{2}' \
    --color='pointer:green,marker:green' |
  awk '{print $1 "/" $2}')

[ -n "$selected_packages" ] || exit 0

set -- $selected_packages
yay -S "$@"
status=$?

printf '\nDone. Press Enter to close...'
read -r _

exit "$status"
