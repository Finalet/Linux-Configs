-- https://wiki.hypr.land/0.56.0/Configuring/Basics/Binds/

hl.config({
    binds = {
        allow_workspace_cycles = true,
    },
})

local mainMod = "SUPER"
local hyper = "SHIFT + CONTROL + ALT"

local function resizeToMonitorFraction(widthFraction, heightFraction)
    return function()
        local monitor = hl.get_active_monitor()
        if monitor == nil then
            return
        end

        local width = monitor.width
        local height = monitor.height
        if monitor.transform % 2 == 1 then
            width, height = height, width
        end

        width = math.floor(width / monitor.scale + 0.5)
        height = math.floor(height / monitor.scale + 0.5)

        hl.dispatch(hl.dsp.window.resize({
            x = math.floor(width * widthFraction),
            y = math.floor(height * heightFraction),
        }))
    end
end

local function minimizeWindow ()
    if hl.get_workspace("special:minimizedWindow") then
        hl.dispatch(hl.dsp.window.move({ workspace = hl.get_active_workspace(), window = "tag:minimized" }))
        hl.dispatch(hl.dsp.window.clear_tags({ window = "tag:minimized" }))
    else
        hl.dispatch(hl.dsp.window.tag({ tag = "minimized", window = hl.get_active_window() }))
        hl.dispatch(hl.dsp.window.move({ workspace = "special:minimizedWindow", follow = false }))
    end
end

-- General management
hl.bind(mainMod .. " + W", hl.dsp.window.close())
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + R", hl.dsp.layout("togglesplit")) -- dwindle
hl.bind(mainMod .. " + G", function() hl.plugin.hyprexpo.expo("toggle") end)
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(hyper .. " + F", hl.dsp.window.fullscreen_state({ internal = 2, client = 0, action = "toggle" }))

-- Toggle floating mode
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + V", resizeToMonitorFraction(0.5, 0.75))

-- Launching apps
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("alacritty"))
hl.bind(hyper .. " + T", hl.dsp.exec_cmd("Telegram"))
hl.bind(hyper .. " + B", hl.dsp.exec_cmd("firefox"))
hl.bind(hyper .. " + G", hl.dsp.exec_cmd("github-desktop"))
hl.bind(hyper .. " + E", hl.dsp.exec_cmd("nautilus"))
hl.bind("CONTROL + SHIFT + ESCAPE", hl.dsp.exec_cmd("resources", { float = true }))

-- Change input language
hl.bind("ALT + SHIFT + Shift_L", hl.dsp.exec_cmd("hyprctl switchxkblayout current next"), { release = true, locked = true })

-- Screenshots
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("hyprshot -m region --clipboard-only --freeze"))
hl.bind("PRINT", hl.dsp.exec_cmd("hyprshot -m output --clipboard-only --freeze"))
hl.bind("SHIFT + PRINT", hl.dsp.exec_cmd("hyprshot -m window --clipboard-only --freeze"))

-- Color picker
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"))

-- Vicinae
hl.bind(mainMod .. " + period", hl.dsp.exec_cmd("vicinae vicinae://launch/core/search-emojis"))
hl.bind("ALT + SPACE", hl.dsp.exec_cmd("vicinae toggle"))

-- Waybar
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("~/.config/hypr/scripts/toggle-waybar.sh"))

-- Alt tabbing workspaces
hl.bind("ALT + tab", hl.dsp.focus({ workspace = "previous_per_monitor" }))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

-- Switch workspaces with mainMod + [0-9]
hl.bind(mainMod .. " + 1", hl.dsp.focus({ workspace = "r~1" }))
hl.bind(mainMod .. " + 2", hl.dsp.focus({ workspace = "r~2" }))
hl.bind(mainMod .. " + 3", hl.dsp.focus({ workspace = "r~3" }))
hl.bind(mainMod .. " + 4", hl.dsp.focus({ workspace = "r~4" }))

-- Move active window to a workspace with mainMod + SHIFT + [0-9]
hl.bind(mainMod .. " + SHIFT + 1", hl.dsp.window.move({ workspace = "r~1" }))
hl.bind(mainMod .. " + SHIFT + 2", hl.dsp.window.move({ workspace = "r~2" }))
hl.bind(mainMod .. " + SHIFT + 3", hl.dsp.window.move({ workspace = "r~3" }))
hl.bind(mainMod .. " + SHIFT + 4", hl.dsp.window.move({ workspace = "r~4" }))

-- Move active window
hl.bind(hyper .. " + left", hl.dsp.window.move({ direction = "left" }))
hl.bind(hyper .. " + up", hl.dsp.window.move({ direction = "up" }))
hl.bind(hyper .. " + down", hl.dsp.window.move({ direction = "down" }))
hl.bind(hyper .. " + right", hl.dsp.window.move({ direction = "right" }))

-- Minimizing window via special workspace
hl.bind(mainMod .. " + M", minimizeWindow)

-- Scratchpad special workspace
hl.bind(hyper .. " + M", hl.dsp.workspace.toggle_special("scratchpad"))
hl.bind(hyper .. " + SUPER + M", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))

-- Move/resize windows with mouse 1 and mouse 2. ALT + LMB and ALT + RMB are controlled via scripts/window-movement-binds.sh
hl.bind("mouse:275", hl.dsp.window.drag(), { mouse = true })
hl.bind("mouse:276", hl.dsp.window.resize(), { mouse = true })

-- Multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume raise"), { repeating = true, locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume lower"), { repeating = true, locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"), { repeating = true, locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("swayosd-client --input-volume mute-toggle"), { repeating = true, locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("swayosd-client --playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("swayosd-client --playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("swayosd-client --playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("swayosd-client --playerctl previous"), { locked = true })
