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

This module exposes **GTK widget IDs** so you can style it from your Waybar `style.css`.

### Widget structure (IDs)

The module creates this hierarchy:

- **Wrapper** (outer container; usually what you size/pad/background)
  - **ID:** `#hypr-ws-apps`
- **Row** (inner container; useful for transitions/min-width)
  - **ID:** `#hypr-ws-apps-row`
- **Icons strip** (actual box that contains icon images)
  - **ID:** `#hypr-ws-apps-icons`

> Note: The module uses fixed IDs for all instances. To style multiple instances differently, see “Multiple instances” below.

---

### State selectors

The module toggles the following state selectors by appending them to the IDs:

#### Empty state (no icons)

Applied when there are **no icons/windows** in the configured workspace:

- `#hypr-ws-apps.empty`
- `#hypr-ws-apps-row.empty`

When there are icons, the module uses:

- `#hypr-ws-apps.nonempty`
- `#hypr-ws-apps-row.nonempty`

#### Active state (workspace is focused)

Applied when the configured workspace is the **currently active workspace**:

- `#hypr-ws-apps.active`
- `#hypr-ws-apps-row.active`

When it is not active:

- `#hypr-ws-apps.inactive`
- `#hypr-ws-apps-row.inactive`

---

### Multiple instances (per-instance styling)

When you configure multiple instances like:

- `cffi/hypr-ws-apps#scratchpad`
- `cffi/hypr-ws-apps#minimizedWindow`

…Waybar’s instance suffix is **not automatically reflected in the module’s IDs**. To style each instance differently, set a `css_class` in the module config; the module will append it as a suffix selector to the same IDs.

Example config:

```jsonc
"cffi/hypr-ws-apps#scratchpad": {
  "module_path": "/home/<user>/.config/waybar/cffi/libhypr_ws_apps.so",
  "workspace": "special:scratchpad",
  "css_class": "scratchpad"
},
"cffi/hypr-ws-apps#minimizedWindow": {
  "module_path": "/home/<user>/.config/waybar/cffi/libhypr_ws_apps.so",
  "workspace": "special:minimizedWindow",
  "css_class": "minimizedWindow"
}
```

Then you can style with:

- `#hypr-ws-apps.scratchpad { ... }`
- `#hypr-ws-apps-row.minimizedWindow { ... }`
- `#hypr-ws-apps-icons.scratchpad { ... }`

---

### Example CSS

```css
#hypr-ws-apps {
  box-shadow: 0px 1px 4px rgba(0, 0, 0, 0.25);
  margin: 6px 4px 4px 4px;
  border-radius: 12px;
  padding: 3px;
  transition: all 0.3s ease-out;
  color: white;
  background: rgba(0, 0, 0, 0.5);
}

#hypr-ws-apps-row {
  transition: all 0.3s ease-out;
  background-color: rgba(255, 255, 255, 0.1);
  border-radius: 9px;
  min-width: 34px;
}

#hypr-ws-apps-row.empty {
  min-width: 0px;
}

#hypr-ws-apps-row.active {
  background-color: rgba(255, 255, 255, 0.75);
}

#hypr-ws-apps.empty {
  margin-left: -4px;
  padding: 0px;
  opacity: 0;
}
```

---

### Quick selector reference (complete)

- Wrapper:

  - `#hypr-ws-apps`
  - `#hypr-ws-apps.empty` / `#hypr-ws-apps.nonempty`
  - `#hypr-ws-apps.active` / `#hypr-ws-apps.inactive`
  - `#hypr-ws-apps.<your-css_class>`

- Row:

  - `#hypr-ws-apps-row`
  - `#hypr-ws-apps-row.empty` / `#hypr-ws-apps-row.nonempty`
  - `#hypr-ws-apps-row.active` / `#hypr-ws-apps-row.inactive`
  - `#hypr-ws-apps-row.<your-css_class>`

- Icons strip:
  - `#hypr-ws-apps-icons`
  - `#hypr-ws-apps-icons.<your-css_class>`

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
