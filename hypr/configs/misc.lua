hl.config({
    -- https://wiki.hypr.land/0.56.0/Configuring/Layouts/Dwindle-Layout/#config
    dwindle = {
        preserve_split = true, -- You probably want this
        precise_mouse_move = true,
    },

    -- https://wiki.hypr.land/0.56.0/Configuring/Layouts/Master-Layout/
    master = {
        new_status = "master",
    },

    -- https://wiki.hypr.land/0.56.0/Configuring/Basics/Variables/#misc
    misc = {
        disable_hyprland_logo = true, -- If true disables the random hyprland logo / anime girl background. :(
        focus_on_activate = true,
        middle_click_paste = false,
    },

    cursor = {
        no_hardware_cursors = 1,
    },
})
