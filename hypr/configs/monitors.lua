-- https://wiki.hypr.land/Configuring/Monitors/

hl.monitor({
    output = "HDMI-A-1",
    mode = "3440x1440@240",
    position = "0x0",
    scale = 1,
})

hl.monitor({
    output = "DP-1",
    mode = "2560x1440@144",
    position = "-1440x-535",
    scale = 1,
    transform = 3,
})

hl.workspace_rule({ workspace = "1", monitor = "HDMI-A-1", persistent = true })
hl.workspace_rule({ workspace = "2", monitor = "HDMI-A-1", persistent = true })
hl.workspace_rule({ workspace = "3", monitor = "HDMI-A-1", persistent = true })
hl.workspace_rule({ workspace = "4", monitor = "HDMI-A-1", persistent = true })
hl.workspace_rule({ workspace = "5", monitor = "DP-1", persistent = true })
hl.workspace_rule({ workspace = "6", monitor = "DP-1", persistent = true })
hl.workspace_rule({ workspace = "7", monitor = "DP-1", persistent = true })
hl.workspace_rule({ workspace = "8", monitor = "DP-1", persistent = true })
