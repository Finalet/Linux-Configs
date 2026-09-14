-- https://wiki.hypr.land/0.56.0/Configuring/Basics/Variables/#input
hl.config({
    input = {
        kb_layout = "us,ru",
        follow_mouse = 1,
        numlock_by_default = true,
        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = true,
            scroll_factor = 0.5,
        },
    },

    gestures = {
        workspace_swipe_distance = 1000,
        workspace_swipe_min_speed_to_force = 10,
    },
})

-- https://wiki.hypr.land/0.56.0/Configuring/Advanced-and-Cool/Gestures/#examples

hl.gesture({ fingers = 3, direction = "swipe", action = "resize" })
hl.gesture({ fingers = 3, direction = "swipe", mods = "ALT", action = "move" })
hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 4, direction = "vertical", action = function() hl.plugin.hyprexpo.expo("toggle") end })
