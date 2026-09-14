-- Setting app themes to dark
hl.exec_cmd('gsettings set org.gnome.desktop.interface gtk-theme "Fluent-round-grey-Dark"') -- for GTK3 apps
hl.exec_cmd('gsettings set org.gnome.desktop.interface icon-theme "Fluent-dark"')
hl.exec_cmd('gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"') -- for GTK4 apps
hl.exec_cmd("gsettings set org.gnome.desktop.interface text-scaling-factor 1") -- Set global scaling for text slightly smaller
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct") -- for Qt apps

hl.config({
    -- https://wiki.hypr.land/Configuring/Variables/#general
    general = {
        gaps_in = 0,
        gaps_out = 0,
        border_size = 2,
        col = {
            active_border = {
                colors = { "rgba(255,255,255,0.4)", "rgba(255,255,255,0.2)" },
                angle = 90,
            },
            inactive_border = "rgba(255,255,255,0.1)",
        },
        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
    },

    -- https://wiki.hypr.land/Configuring/Variables/#decoration
    decoration = {
        rounding = 10,
        rounding_power = 2,
        active_opacity = 0.95,
        inactive_opacity = 0.95,
        shadow = {
            enabled = true,
            range = 36,
            render_power = 1,
            scale = 0.97,
            color = "rgba(0,0,0,0.35)",
            offset = { 0, 15 },
        },
        blur = {
            enabled = true,
            size = 8,
            passes = 2,
            vibrancy = 0.1696,
            popups = true,
        },
    },

    animations = {
        enabled = true,
    },
})

-- Default curves, see https://wiki.hypr.land/Configuring/Animations/#curves
hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })
hl.curve("easeOutBack", { type = "bezier", points = { { 0.3, 1.15 }, { 0.5, 1 } } })

-- Default animations, see https://wiki.hypr.land/Configuring/Animations/
hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 2.5, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, bezier = "easeOutBack" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "easeOutQuint", style = "slide" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 4, bezier = "easeOutQuint", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, bezier = "easeOutQuint", style = "slidefadevert 10%" })
hl.animation({ leaf = "specialWorkspaceIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "slidefadevert 10%" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 4, bezier = "easeOutQuint", style = "slidefadevert 10%" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 7, bezier = "quick" })
