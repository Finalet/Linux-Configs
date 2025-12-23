# hypr-ws-apps-icon (Waybar CFFI module for Hyprland)

A **Waybar CFFI** module for **Hyprland** that displays **application icons** for windows currently present in a **user-specified Hyprland workspace**.

- Event-driven: listens to Hyprland’s event socket (`.socket2.sock`) for fast updates.
- Uses real application icons via GTK icon theme / desktop entries (no font icons / icon maps).
- Configurable workspace, icon size, spacing, max icons, tooltip, and empty behavior.
- CSS-stylable (wrapper + row + icon-strip + per-icon class, plus `.empty` state).

---

## Requirements

- Waybar built with **CFFI module support** (and using the ABI header you built against).
- Hyprland (running) with environment variables available to Waybar:
  - `XDG_RUNTIME_DIR`
  - `HYPRLAND_INSTANCE_SIGNATURE`
- `hyprctl` in PATH (the module calls `hyprctl -j clients`)
- Build deps:
  - `gtk+-3.0`
  - `glib-2.0`
  - `gio-2.0`
  - `json-glib-1.0`
  - a C++20 compiler (g++/clang++)

### Arch Linux deps example

```bash
sudo pacman -S --needed gcc pkgconf gtk3 json-glib
```

---

## Build

Place `hypr_ws_apps_icon.cpp` next to your `waybar_cffi_module.h` (get it from [Waybar repo](https://github.com/Alexays/Waybar/blob/master/resources/custom_modules/cffi_example/waybar_cffi_module.h), it must match your installed Waybar CFFI ABI).

Build the shared library:

```bash
g++ -shared -fPIC -O2 -std=c++20 hypr_ws_apps_icon.cpp -o libhypr_ws_apps.so \
  $(pkg-config --cflags --libs gtk+-3.0 gio-2.0 glib-2.0 json-glib-1.0)
```

Install it:

```bash
mkdir -p ~/.config/waybar/cffi
cp libhypr_ws_apps.so ~/.config/waybar/cffi/libhypr_ws_apps.so
```

---

## Run / Load in Waybar

### Important

Waybar does **not** expand `~` in `module_path`. Use an absolute path.

Add to `~/.config/waybar/config.jsonc`:

```jsonc
{
  "modules-center": ["hyprland/workspaces", "cffi/hypr-ws-apps"],
  "cffi/hypr-ws-apps": {
    "module_path": "/home/<user>/.config/waybar/cffi/libhypr_ws_apps.so",
    "workspace": "1",
    "icon_size": 16,
    "spacing": 8,
    "max_icons": 12,
    "show_empty": false,
    "tooltip": true
  }
}
```

Restart Waybar:

```bash
pkill waybar
waybar
```

To view logs:

```bash
WAYBAR_LOG_LEVEL=trace waybar 2>&1 | tee /tmp/waybar.log
```

---

## Configuration

All config fields are read from the Waybar module config object.

| Key          |   Type | Default | Description                                                                                                    |
| ------------ | -----: | ------: | -------------------------------------------------------------------------------------------------------------- |
| `workspace`  | string |   `"1"` | Workspace selector. Matches either Hyprland workspace `id` (e.g. `"2"`) or workspace `name` (e.g. `"2:code"`). |
| `icon_size`  |    int |    `18` | Icon size in pixels. Applied via `gtk_image_set_pixel_size()`.                                                 |
| `spacing`    |    int |     `6` | Space in pixels between icons (applied as right margin). The last icon has **no** trailing margin.             |
| `max_icons`  |    int |     `0` | Maximum number of icons to show. `0` = unlimited.                                                              |
| `show_empty` |   bool | `false` | If `false`, hides the module when the workspace has no matching windows.                                       |
| `tooltip`    |   bool |  `true` | If `true`, shows tooltip containing app class/title list.                                                      |

---

## Styling (CSS)

This module provides GTK widget IDs / classes for styling:

### Containers

- Wrapper (outer, expands):

  - ID: `#hypr-ws-apps`
  - Class: `.hypr-ws-apps`
  - State classes applied here: `.empty` / `.nonempty`

- Row container:

  - ID: `#hypr-ws-apps-row`
  - Class: `.hypr-ws-apps-row`
  - State classes also applied here: `.empty` / `.nonempty`

- Icon strip (actual icon box inside the row):
  - ID: `#hypr-ws-apps-icons`
  - Class: `.hypr-ws-apps-icons`

### Per-icon

- Each icon gets class: `.hypr-ws-apps-icon`

### Example `~/.config/waybar/style.css`

```css
/* Outer wrapper: size/background */
#hypr-ws-apps {
  padding: 0 10px;
  border-radius: 10px;
  background: rgba(255, 255, 255, 0.06);
}

/* Row container (optional styling) */
#hypr-ws-apps-row {
  padding: 2px 6px;
  border-radius: 8px;
}

/* Center strip styling */
#hypr-ws-apps-icons {
  /* e.g. add subtle background behind icons */
  /* background: rgba(0,0,0,0.15); */
  border-radius: 8px;
}

/* Per-icon styling */
#hypr-ws-apps-icons {
  padding: 2px;
}

/* Empty state */
#hypr-ws-apps.empty,
#hypr-ws-apps-row.empty {
  opacity: 0.35;
  background: transparent;
}
```

---

## How it works (high level)

1. Connects to Hyprland’s event socket:  
   `"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"`
2. On relevant events (open/close/move/workspace), requests an update on the GTK main loop.
3. Queries current windows via:  
   `hyprctl -j clients`
4. Filters clients belonging to the configured workspace.
5. Resolves application icons using installed `.desktop` files (`Icon=` + `StartupWMClass=`/desktop filename matching).
6. Displays icons as GTK images in the module.

---

## Troubleshooting

### Module doesn’t appear

- Ensure `module_path` is an absolute path (no `~`).
- Ensure the library loads:
  ```bash
  ldd ~/.config/waybar/cffi/libhypr_ws_apps.so
  ```
- Ensure Waybar has Hyprland env vars:
  ```bash
  echo "$XDG_RUNTIME_DIR"
  echo "$HYPRLAND_INSTANCE_SIGNATURE"
  ```
- Ensure `hyprctl` is available in Waybar’s PATH:
  ```bash
  command -v hyprctl
  ```

### No icons shown

- Verify the workspace name/id matches:
  ```bash
  hyprctl -j workspaces | jq 'map({id,name})'
  ```
- Test clients:
  ```bash
  hyprctl -j clients | jq '.[].workspace'
  ```

---

## License

Unspecified (use whatever license you prefer for your dotfiles/module).
