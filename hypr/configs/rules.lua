-- https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Ignore maximize requests from apps. You'll probably like this.
hl.window_rule({
    name = "ignore-maximize",
    suppress_event = "maximize",
    match = { class = ".*" },
})

-- Fix some dragging issues with XWayland
hl.window_rule({
    name = "xwayland-drag-fix",
    no_focus = true,
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
})

-- Vicinae
hl.layer_rule({
    name = "vicinae-blur",
    blur = true,
    ignore_alpha = 0,
    match = { namespace = "vicinae" },
})

hl.window_rule({
    name = "vicinae-borderless",
    border_size = 0,
    match = { class = "vicinae" },
})

-- Swaync
hl.layer_rule({
    name = "swaync-control-center-blur",
    blur = true,
    ignore_alpha = 0.5,
    animation = "slide right",
    match = { namespace = "swaync-control-center" },
})

hl.layer_rule({
    name = "swaync-notification-window-blur",
    blur = true,
    ignore_alpha = 0.5,
    match = { namespace = "swaync-notification-window" },
})

-- Swayosd
hl.layer_rule({
    name = "swayosd-blur",
    blur = true,
    ignore_alpha = 0.3,
    match = { namespace = "swayosd" },
})

-- Media viewers should be opaque to not mess with the content
hl.window_rule({
    name = "media-viewers-opaque",
    opaque = true,
    float = true,
    match = { class = "(org.gnome.Loupe|(.*)(Celluloid))" },
})

-- Waybar
hl.layer_rule({
    name = "waybar-blur",
    blur = true,
    ignore_alpha = 0.3,
    match = { namespace = "waybar" },
})
