if hl.plugin.hyprexpo then
    hl.config({
        plugin = {
            hyprexpo = {
                columns = 2,
                gaps_in = 5,
                bg_col = "rgb(111111)",
                workspace_method = "first 1", -- [center/first] [workspace] e.g. first 1 or center m+1
                gesture_distance = 300, -- how far is the "max" for the gesture
            },
        },
    })
end

if hl.plugin.dynamic_cursors then
    hl.config({
        plugin = {
            dynamic_cursors = {
                mode = "stretch",
            },
        },
    })
end
