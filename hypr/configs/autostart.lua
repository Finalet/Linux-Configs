hl.on("hyprland.start", function()
    hl.exec_cmd("waybar") -- menu bar
    hl.exec_cmd("hyprpaper") -- wallpapers
    hl.exec_cmd('EMOJI_FONT="Apple Color Emoji" vicinae server') -- application launcer
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1") -- authentication agent
    hl.exec_cmd("hyprpm reload") --plugins
    hl.exec_cmd("~/.config/hypr/scripts/window-movement-binds.sh code") -- custom window movement binds
    hl.exec_cmd("swaync") -- notification daemon
    hl.exec_cmd("swayosd-server") -- osd daemon
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP") -- Screen sharing
    hl.exec_cmd("hypridle") -- idle management daemon

    -- Uncomment below to enable a lockscreen on computer start-up.
    -- hl.exec_cmd("hyprlock || hyprctl dispatch 'hl.dsp.exit()'")
end)
