-- https://wiki.hypr.land/0.56.0/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "28")
hl.env("HYPRCURSOR_THEME", "rose-pine-hyprcursor")

-- Nvidia drivers
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("NVD_BACKEND", "direct")

-- Open file with menu
hl.env("XDG_MENU_PREFIX", "arch-")

-- Force wayland for apps
hl.env("GDK_BACKEND", "wayland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("SDL_VIDEODRIVER", "wayland")

-- Running GTK apps with cairo (CPU) renderer, because otherwise the context menus are lagging.
hl.env("GSK_RENDERER", "cairo")