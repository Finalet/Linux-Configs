# Linux-Configs (Arch + Hyprland)

This repo contains my Arch Linux dotfiles for a Hyprland-based Wayland desktop.

## What’s in this repo

- `hypr/` — Hyprland config (`hyprland.conf` + `configs/` includes) and helper scripts
- `waybar/` — Waybar config + styling, plus a custom CFFI module (`hypr-ws-apps/`)
- `swaync/` — Sway Notification Center config + styling
- `ghostty/` — Ghostty terminal config

## Install packages

Below are the packages I had installed when these dotfiles were captured.

### Official repo packages (pacman)

```txt
amd-ucode
archlinux-xdg-menu
ark
base
base-devel
bluez
bluez-utils
cli11
cmake
cpio
dkms
dolphin
efibootmgr
fastfetch
firefox
fzf
ghostty
git
gnome-calendar
gnome-keyring
grub
gst-plugin-pipewire
htop
hypridle
hyprland
hyprlock
hyprpaper
hyprpicker
hyprshot
inotify-tools
iwd
jemalloc
kate
konsole
libpulse
libva-nvidia-driver
linux-firmware
linux-zen
linux-zen-headers
lxappearance
meson
nano
nautilus
neovim
network-manager-applet
networkmanager
nodejs
npm
nvidia-dkms
nwg-look
obs-studio
os-prober
otf-font-awesome
pavucontrol
pipewire
pipewire-alsa
pipewire-jack
pipewire-pulse
plasma-meta
plasma-workspace
qt5-wayland
qt6ct
sassc
smartmontools
swaync
telegram-desktop
ttf-nerd-fonts-symbols
vim
waybar
wget
wireless_tools
wireplumber
woff2-font-awesome
xdg-desktop-portal-hyprland
xdg-utils
xorg-xinit
zram-generator
zsh-completions
```

Install:

```bash
sudo pacman -Syu
sudo pacman -S --needed \
  amd-ucode archlinux-xdg-menu ark base base-devel bluez bluez-utils \
  cli11 cmake cpio dkms dolphin efibootmgr fastfetch firefox fzf ghostty git \
  gnome-calendar gnome-keyring grub gst-plugin-pipewire htop hypridle hyprland \
  hyprlock hyprpaper hyprpicker hyprshot inotify-tools iwd jemalloc kate konsole \
  libpulse libva-nvidia-driver linux-firmware linux-zen linux-zen-headers \
  lxappearance meson nano nautilus neovim network-manager-applet networkmanager \
  nodejs npm nvidia-dkms nwg-look obs-studio os-prober otf-font-awesome \
  pavucontrol pipewire pipewire-alsa pipewire-jack pipewire-pulse plasma-meta \
  plasma-workspace qt5-wayland qt6ct sassc smartmontools swaync telegram-desktop \
  ttf-nerd-fonts-symbols vim waybar wget wireless_tools wireplumber woff2-font-awesome \
  xdg-desktop-portal-hyprland xdg-utils xorg-xinit zram-generator zsh-completions
```

### AUR packages (yay)

```txt
actions-for-nautilus-git
dms-shell-bin-debug
docker-desktop
github-desktop-bin
google-breakpad
hellwal
hyprshutdown-git
nautilus-admin-gtk4
nautilus-open-any-terminal
otf-apple-sf-pro
postman-bin
rose-pine-hyprcursor
vesktop
vicinae-bin
visual-studio-code-bin
yay-bin
yay-bin-debug
```

Install `yay` (if you don’t already have it):

```bash
sudo pacman -S --needed git base-devel
cd /tmp
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si
```

Then install AUR packages:

```bash
yay -S --needed \
  actions-for-nautilus-git dms-shell-bin-debug docker-desktop github-desktop-bin \
  google-breakpad hellwal hyprshutdown-git nautilus-admin-gtk4 nautilus-open-any-terminal \
  otf-apple-sf-pro postman-bin rose-pine-hyprcursor vesktop vicinae-bin \
  visual-studio-code-bin yay-bin yay-bin-debug
```

## Enable services

At minimum:

```bash
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth
```

Notes:

- If you prefer `iwd` directly (without NetworkManager), enable it instead. If you’re using NetworkManager, you typically don’t need to enable `iwd` as a separate service unless you know you want that setup.
- Audio is PipeWire (`pipewire` + `wireplumber`) and is usually started as user services automatically.

## Deploy dotfiles

This repo is laid out to mirror `~/.config`.

```bash
# from the repo root
mkdir -p ~/.config

# Hyprland
mkdir -p ~/.config/hypr
cp -r hypr/* ~/.config/hypr/

# Waybar
mkdir -p ~/.config/waybar
cp -r waybar/* ~/.config/waybar/

# SwayNC
mkdir -p ~/.config/swaync
cp -r swaync/* ~/.config/swaync/

# Ghostty
mkdir -p ~/.config/ghostty
cp -r ghostty/* ~/.config/ghostty/
```

## Post-install notes (important)

### 1) Waybar custom module path is hard-coded

In `waybar/config.jsonc`, the `module_path` currently points at `/home/grant/...`.
Waybar **does not expand `~`** inside `module_path`, so you must use an absolute path.

Fix it after copying:

```bash
sed -i "s|/home/grant|/home/$USER|g" ~/.config/waybar/config.jsonc
```

Then follow the build/install instructions in `waybar/hypr-ws-apps/README.md` to compile/copy `libhypr_ws_apps.so`.

### 2) Wallpaper file required

The wallpaper reload script expects:

- `~/.config/hypr/wallpaper/wallpaper.png`

Create/copy a wallpaper there, then you can reload it and regenerate colors:

```bash
~/.config/hypr/scripts/reload-wallpaper.sh
```

This script uses `hellwal` and `jq` to generate `~/.config/hypr/wallpaper/colors.css`.

### 3) Polkit agent

Hyprland autostart runs:

- `/usr/lib/polkit-kde-authentication-agent-1`

This is typically provided by KDE/Plasma packages (you have `plasma-meta` installed). If you remove Plasma, install a polkit agent alternative.

### 4) Hyprland plugins (hyprexpo)

These configs reference the `hyprexpo` plugin (see `hypr/configs/plugins.conf`) and start `hyprpm reload` on login.
If the expo bind doesn’t work, install/enable the plugin via `hyprpm` (exact steps depend on your Hyprland version).

## Launching Hyprland

How you start Hyprland is up to you (display manager, greetd, or tty). For a simple manual start from TTY you can create an executable `~/.xinitrc` that runs `Hyprland` and start it with `startx` (note: many Hyprland setups use greetd or a DM instead).

## Troubleshooting checklist

- `waybar` doesn’t show workspace icons: confirm the CFFI module is built and `module_path` is correct.
- Notifications don’t work: `swaync` should be running (it’s started in `hypr/configs/autostart.conf`).
- Screenshot / picker binds do nothing: ensure `hyprshot` and `hyprpicker` are installed.
- Wallpaper colors not updating: ensure `hellwal` and `jq` exist and `wallpaper.png` is present.
