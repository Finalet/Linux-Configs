#!/usr/bin/env bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_DIR="$SCRIPT_DIR"
BACKUP_ROOT="$HOME/.local/state/linux-configs-backups"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"
TEMP_DIR=""
MONITOR_SETUP_MODE=""
SUDO_KEEPALIVE_PID=""

REQUIRED_PACMAN_PACKAGES=(
  # Dev utilities
  alacritty
  git
  base-devel
  yad
  neovim
  # Zsh
  zsh
  zsh-autosuggestions
  zsh-syntax-highlighting
  # Fonts
  ttf-nerd-fonts-symbols
  ttf-roboto
  otf-font-awesome
  noto-fonts-cjk
  # System apps
  gnome-calendar
  gnome-disk-utility
  celluloid
  resources
  nautilus
  # Desktop components
  waybar
  swaync
  swayosd
  # Hyprland utilities
  hypridle
  hyprland
  hyprlock
  hyprpaper
  hyprpicker
  hyprshot
  # Audio
  pavucontrol
  pipewire
  pipewire-pulse
  playerctl
  # System services
  polkit-gnome
  brightnessctl
  networkmanager
  xdg-desktop-portal-hyprland
  # Hyprpm dependencies
  cmake
  cpio
  # Other utilities
  fzf
  keyd
  dbus
  glib2
  gsettings-desktop-schemas
  jq
  libnotify
  procps-ng
  qt6ct
  socat
  wireplumber
  wl-clipboard
  wtype
)

REQUIRED_AUR_PACKAGES=(
  # Cursor
  rose-pine-hyprcursor
  # Fonts
  otf-apple-sf-pro
  ttf-apple-emoji
  # System apps
  nautilus-dropbox
  nautilus-admin-gtk4
  # Other utilities
  vicinae-bin
  hyprhalt
)

OPTIONAL_PACKAGE_SUGGESTIONS=(
  ghostty
  firefox
  chromium
  telegram-desktop
  visual-studio-code-bin
  github-desktop-bin
  dropbox
  libreoffice-still
  fastfetch
  obs-studio
  teamspeak3
  vesktop
)

OPTIONAL_PACKAGES=()

HYPRPM_PLUGIN_SOURCES=(
  https://github.com/hyprwm/hyprland-plugins
)

HYPRPM_ENABLED_PLUGINS=(
  hyprexpo
)

USER_SYMLINKS=(
  "$REPO_DIR/ghostty:$HOME/.config/ghostty"
  "$REPO_DIR/hypr:$HOME/.config/hypr"
  "$REPO_DIR/hyprhalt:$HOME/.config/hyprhalt"
  "$REPO_DIR/swaync:$HOME/.config/swaync"
  "$REPO_DIR/swayosd:$HOME/.config/swayosd"
  "$REPO_DIR/vicinae:$HOME/.config/vicinae"
  "$REPO_DIR/waybar:$HOME/.config/waybar"
  "$REPO_DIR/zsh/.zshrc:$HOME/.zshrc"
  "$REPO_DIR/zsh/.p10k.zsh:$HOME/.p10k.zsh"
)

SYSTEM_SYMLINKS=(
  "$REPO_DIR/keyd:/etc/keyd"
)

start () {
  StartingInstallation
  CheckEnvironment
  PromptConfigurationOptions
  ConfirmReadyToStart
  PrepareWorkspace
  InstallYAY
  InstallPacmanPackages
  InstallAURPackages
  InstallOptionalPackages
  SetupZSH
  SetupGPU
  SetupUserSymlinks
  SetupDesktopEntries
  SetupSystemSymlinks
  SetupMonitors
  SetupHyprlandPlugins
  ConfigureWaybar
  SetupServices
  RefreshDesktopDatabase
  ValidateInstallation
  Cleanup
  InstallationCompleted
  PromptForHyprlandRestart
}

StartingInstallation () {
  printf "\n\n--- 🤨 Oh, hi there, little buddy 🤨 ---\n"
  printf "\nYou are a meme-big-boy looser, aren't ya? Don't got no arch hyprland config of your own, huh? Gotta snatch someone elses, huh? What a looser. What an animal. What a permanent underclass. If I were you I'd kill myself already. But hey, here you are, stealing my dot files. Good luck fixing anything when it breaks. What a disappointment you are. Disgrace.\n"
  printf "\nOkay, first things first, give me your sudo password, bitch 👊💢.\n\n"
}

CheckEnvironment () {
  logInfo 'Checking installer environment'

  if [[ ! -f /etc/arch-release ]]; then
    logError 'This installer only supports Arch Linux.'
    exit 1
  fi

  # if [[ $EUID -eq 0 ]]; then
  #   logError 'Run this script as your normal user, not as root.'
  #   exit 1
  # fi

  commandExists sudo || {
    logError 'sudo is required to install packages and create system symlinks.'
    exit 1
  }

  commandExists hyprctl || {
    logError 'hyprctl is required. Run this installer from an active Hyprland session.'
    exit 1
  }

  if [[ -z ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
    logError 'This installer must be run from an active Hyprland session.'
    exit 1
  fi

  run sudo -v
  StartSudoKeepAlive
}

StartSudoKeepAlive () {
  local parentPid=$$

  [[ -n ${SUDO_KEEPALIVE_PID:-} ]] && return

  # Keep sudo authentication fresh for the duration of the installer.
  while kill -0 "$parentPid" >/dev/null 2>&1; do
    sudo -n -v >/dev/null 2>&1 || break
    sleep 30
  done &

  SUDO_KEEPALIVE_PID=$!
}

StopSudoKeepAlive () {
  [[ -n ${SUDO_KEEPALIVE_PID:-} ]] || return

  kill "$SUDO_KEEPALIVE_PID" >/dev/null 2>&1 || true
  wait "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
  SUDO_KEEPALIVE_PID=""
}

PromptConfigurationOptions () {
  PromptForMonitorSetupMode
  PromptForOptionalPackages
}

ConfirmReadyToStart () {
  local confirmationOptions=(
    'Start'
    'Cancel'
  )
  local countdown
  local selectedConfirmation=()

  selectOptions confirmationOptions selectedConfirmation single true "Ready to start installation? This will make changes to your system which cannot be undone automatically. Backups will be created in $BACKUP_ROOT."

  if [[ ${selectedConfirmation[0]} != 'Start' ]]; then
    logInfo 'Installation cancelled before making changes.'
    exit 0
  fi

    logInfo 'Starting installation in 5 seconds. Press Ctrl+C to abort.'
    for ((countdown = 5; countdown > 0; countdown--)); do
      printf 'Starting in %d...\r' "$countdown"
      sleep 1
    done
    printf '%s\n' 'Starting now.'
}

PromptForOptionalPackages () {
  local optionalPackageOptions=("${OPTIONAL_PACKAGE_SUGGESTIONS[@]}" 'Provide custom packages [enter manually]')
  local selectedOptions=()
  local customPackages=()
  local selectedOption
  local selectionLabel='Select optional packages that you would like to install, you lazy dweeb.'

  selectOptions optionalPackageOptions selectedOptions multiple false "$selectionLabel"

  OPTIONAL_PACKAGES=()

  for selectedOption in "${selectedOptions[@]}"; do
    if [[ $selectedOption == 'Provide custom packages [enter manually]' ]]; then
      promptForPackageList 'Enter additional packages to install with yay [optional, space-separated, idiota]: ' customPackages
      BuildUniquePackageList OPTIONAL_PACKAGES "${OPTIONAL_PACKAGES[@]}" "${customPackages[@]}"
      continue
    fi

    OPTIONAL_PACKAGES+=("$selectedOption")
  done

  BuildUniquePackageList OPTIONAL_PACKAGES "${OPTIONAL_PACKAGES[@]}"
}

PromptForMonitorSetupMode () {
  local monitorOptions=(
    "Keep monitor configuration from the repo, I'm stupid and scared to change anything."
    "Auto-generate monitor configuration, I'm lazy and want to die."
    "Provide custom configuration, I like to eat my own shit."
  )
  local selectedMonitorOption=()

  selectOptions monitorOptions selectedMonitorOption single true 'How you would like mommy to configure your monitors, big boy?'

  case "${selectedMonitorOption[0]}" in
    "Keep monitor configuration from the repo, I'm stupid and scared to change anything.")
      MONITOR_SETUP_MODE='keep'
      ;;
    "Auto-generate monitor configuration, I'm lazy and want to die.")
      MONITOR_SETUP_MODE='auto'
      ;;
    "Provide custom configuration, I like to eat my own shit.")
      MONITOR_SETUP_MODE='custom'
      ;;
    *)
      logError 'Unknown monitor setup option selected.'
      exit 1
      ;;
  esac
}

PrepareWorkspace () {
  logInfo 'Preparing installer workspace'

  TEMP_DIR=$(mktemp -d)
  run mkdir -p "$HOME/.config"
  run mkdir -p "$HOME/.local/share/applications"
  run mkdir -p "$BACKUP_DIR"
}

InstallYAY () {
  commandExists yay && {
    logInfo 'YAY is already installed'
    return
  }

  logInfo 'Installing YAY'

  run sudo pacman -S --needed --noconfirm git base-devel

  run git clone https://aur.archlinux.org/yay-bin.git "$TEMP_DIR/yay-bin"
  pushd "$TEMP_DIR/yay-bin" >/dev/null || {
    logError 'Failed to enter temporary YAY build directory.'
    exit 1
  }
  run makepkg -si --noconfirm
  popd >/dev/null || true

  run yay -Sy
}

InstallPacmanPackages () {
  local packages=()

  BuildUniquePackageList packages "${REQUIRED_PACMAN_PACKAGES[@]}"

  logInfo 'Installing pacman packages required by this configuration'
  run sudo pacman -S --needed --noconfirm "${packages[@]}"
}

InstallAURPackages () {
  local packages=()

  BuildUniquePackageList packages "${REQUIRED_AUR_PACKAGES[@]}"

  [[ ${#packages[@]} -eq 0 ]] && return

  logInfo 'Installing AUR packages required by this configuration'
  run yay -S --needed --noconfirm "${packages[@]}" --mflags --skipchecksums
}

InstallOptionalPackages () {
  local packages=()

  BuildUniquePackageList packages "${OPTIONAL_PACKAGES[@]}"

  [[ ${#packages[@]} -eq 0 ]] && return

  logInfo 'Installing optional packages selected for this machine'
  run yay -S --needed --noconfirm "${packages[@]}"
}

SetupZSH () {
  local ohMyZshDirectory="$HOME/.oh-my-zsh"
  local themeDirectory="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

  if [[ ! -d $ohMyZshDirectory ]]; then
    logInfo 'Installing Oh My Zsh'
    run sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  else
    logInfo 'Oh My Zsh is already installed'
  fi

  if [[ -d $themeDirectory ]]; then
    logInfo 'Powerlevel10k theme is already installed'
  else
    logInfo 'Installing Powerlevel10k theme for ZSH'
    run git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$themeDirectory"
  fi

  logInfo 'Setting zsh as the default shell'
  run sudo chsh -s $(which zsh)
}

SetupUserSymlinks () {
  local mapping source target

  logInfo 'Creating user config symlinks'

  for mapping in "${USER_SYMLINKS[@]}"; do
    source=${mapping%%:*}
    target=${mapping#*:}
    BackupTargetIfNeeded "$source" "$target"
    EnsureParentDirectory "$target"
    run ln -sfnT "$source" "$target"
  done
}

SetupGPU () {
  local envConfigPath aqDrmDevicesPattern tempFile

  envConfigPath="$REPO_DIR/hypr/configs/env.conf"
  aqDrmDevicesPattern='^[[:space:]]*env[[:space:]]*=[[:space:]]*AQ_DRM_DEVICES,'

  if [[ ! -f $envConfigPath ]]; then
    logError "GPU setup failed: expected env config at $envConfigPath"
    exit 1
  fi

  if ! grep -Eq "$aqDrmDevicesPattern" "$envConfigPath"; then
    logInfo 'No AQ_DRM_DEVICES override found in env.conf'
    return
  fi

  logInfo 'Removing AQ_DRM_DEVICES override from env.conf because its system specific.'
  tempFile=$(mktemp)

  awk '!match($0, /^[[:space:]]*env[[:space:]]*=[[:space:]]*AQ_DRM_DEVICES,/) { print }' "$envConfigPath" > "$tempFile"
  run mv "$tempFile" "$envConfigPath"
}

SetupDesktopEntries () {
  local desktopFile targetFile

  logInfo 'Creating .desktop files symlinks'

  for desktopFile in "$REPO_DIR"/hypr/apps/*.desktop; do
    targetFile="$HOME/.local/share/applications/$(basename "$desktopFile")"
    BackupTargetIfNeeded "$desktopFile" "$targetFile"
    EnsureParentDirectory "$targetFile"
    run ln -sfnT "$desktopFile" "$targetFile"
  done
}

SetupSystemSymlinks () {
  local mapping source target

  logInfo 'Creating system config symlinks'

  for mapping in "${SYSTEM_SYMLINKS[@]}"; do
    source=${mapping%%:*}
    target=${mapping#*:}
    BackupTargetIfNeeded "$source" "$target"
    EnsureParentDirectory "$target"
    run sudo ln -sfnT "$source" "$target"
  done
}

SetupMonitors () {
  local monitorsJson monitorRows monitorConfig

  case "$MONITOR_SETUP_MODE" in
    keep)
      logInfo 'Keeping monitor configuration from the repo'
      return
      ;;
    auto)
      logInfo 'Auto-generating monitor configuration from current Hyprland session'
      ;;
    custom)
      logInfo 'Collecting custom monitor configuration from current Hyprland session'
      ;;
    *)
      logError 'Monitor setup mode was not configured.'
      exit 1
      ;;
  esac

  monitorsJson=$(hyprctl monitors -j 2>/dev/null) || {
    logError 'Failed to read monitor information from hyprctl monitors -j.'
    exit 1
  }

  monitorRows=$(printf '%s\n' "$monitorsJson" | jq -r '.[] | select((.disabled // false) | not) | [.name, .width, .height, .refreshRate] | @tsv')

  if [[ -z $monitorRows ]]; then
    logError 'No active monitors were reported by hyprctl monitors -j.'
    exit 1
  fi

  case "$MONITOR_SETUP_MODE" in
    auto)
      monitorConfig=$(BuildAutoMonitorConfiguration "$monitorRows")
      ;;
    custom)
      monitorConfig=$(BuildCustomMonitorConfiguration "$monitorRows")
      ;;
  esac

  printf '%s\n' "$monitorConfig" > "$REPO_DIR/hypr/configs/monitors.conf"

  logInfo 'Updated hypr/configs/monitors.conf'
}

SetupHyprlandPlugins () {
  local pluginSource pluginName

  commandExists hyprpm || {
    logError 'hyprpm is required to install Hyprland plugins.'
    exit 1
  }

  logInfo 'Updating Hyprland plugin registry'
  run hyprpm update -f

  for pluginSource in "${HYPRPM_PLUGIN_SOURCES[@]}"; do
    logInfo "Adding Hyprland plugin source: $pluginSource"
    run hyprpm add "$pluginSource" -f
  done

  for pluginName in "${HYPRPM_ENABLED_PLUGINS[@]}"; do
    logInfo "Enabling Hyprland plugin: $pluginName"
    run hyprpm enable "$pluginName" -f
  done
}

ConfigureWaybar () {
  local waybarConfigPath monitorsJson monitorNamesJson tempConfigFile

  waybarConfigPath="$REPO_DIR/waybar/config.jsonc"
  
  logInfo 'Configuring Waybar outputs from active monitors'

  monitorsJson=$(hyprctl monitors -j 2>/dev/null) || {
    logError 'Failed to read monitor information from hyprctl monitors -j for Waybar configuration.'
    exit 1
  }

  monitorNamesJson=$(printf '%s\n' "$monitorsJson" | jq -c '[.[] | select((.disabled // false) | not) | .name]') || {
    logError 'Failed to parse active monitor names for Waybar configuration.'
    exit 1
  }

  if [[ $monitorNamesJson == '[]' ]]; then
    logError 'No active monitors were reported by hyprctl monitors -j for Waybar configuration.'
    exit 1
  fi

  tempConfigFile=$(mktemp)

  JsoncToJson "$waybarConfigPath" | jq --argjson monitors "$monitorNamesJson" '
    (.[0] // error("waybar/config.jsonc must contain at least one array element")) as $primary
    | ((.[1] // .[0])) as $secondary
    | [($primary | .output = $monitors[0])] + [$monitors[1:][] | ($secondary | .output = .)]
  ' > "$tempConfigFile" || {
    rm -f "$tempConfigFile"
    logError 'Failed to rebuild Waybar monitor configuration.'
    exit 1
  }

  run mv "$tempConfigFile" "$waybarConfigPath"
  logInfo 'Updated waybar/config.jsonc outputs for active monitors'
}

JsoncToJson () {
  local jsoncFile=$1

  sed -E '/^[[:space:]]*\/\//d; s/[[:space:]]*\/\/.*$//' "$jsoncFile" | perl -0pe 's/,(\s*[\]}])/$1/g'
}

BuildAutoMonitorConfiguration () {
  local monitorRows=$1
  local output width height refresh

  {
    printf '# Auto-generated by install.sh using `hyprctl monitors -j`\n\n'

    while IFS=$'\t' read -r output width height refresh; do
      [[ -z $output ]] && continue
      printf 'monitorv2 {\n'
      printf '  output = %s\n' "$output"
      printf '  mode = %sx%s@%s\n' "$width" "$height" "$refresh"
      printf '  position = auto\n'
      printf '  scale = 1\n'
      printf '}\n'
    done <<< "$monitorRows"

    printf '\n'
    BuildWorkspaceAssignments "$monitorRows"
  }
}

BuildCustomMonitorConfiguration () {
  local monitorRows=$1
  local output width height refresh positionX positionY scale

  {
    printf '# Auto-generated by install.sh using `hyprctl monitors -j` with user-provided positions\n\n'

    while IFS=$'\t' read -r output width height refresh; do
      [[ -z $output ]] && continue

      PromptForMonitorCoordinate "$output" 'X' positionX
      PromptForMonitorCoordinate "$output" 'Y' positionY
      PromptForMonitorScale "$output" scale

      printf 'monitorv2 {\n'
      printf '  output = %s\n' "$output"
      printf '  mode = %sx%s@%s\n' "$width" "$height" "$refresh"
      printf '  position = %sx%s\n' "$positionX" "$positionY"
      printf '  scale = %s\n' "$scale"
      printf '}\n'
    done <<< "$monitorRows"

    printf '\n'
    BuildWorkspaceAssignments "$monitorRows"
  }
}

BuildWorkspaceAssignments () {
  local monitorRows=$1
  local output workspaceIndex workspaceCountI 

  workspaceIndex=1
  while IFS=$'\t' read -r output _; do
    [[ -z $output ]] && continue
    workspaceCount=0
    while (( workspaceCount < 4 )); do
      printf 'workspace = %d, monitor:%s, persistent:true\n' "$workspaceIndex" "$output"
      ((workspaceIndex++))
      ((workspaceCount++))
    done
  done <<< "$monitorRows"
}

PromptForMonitorCoordinate () {
  local output=$1
  local axis=$2
  local -n resultRef=$3

  while true; do
    promptForValue "Enter ${axis} position for monitor ${output}: " resultRef

    if [[ $resultRef =~ ^-?[0-9]+$ ]]; then
      return
    fi

    logError 'Please enter an integer value.'
  done
}

PromptForMonitorScale () {
  local output=$1
  local -n resultRef=$2

  while true; do
    promptForValue "Enter scale for monitor ${output} [default: 1]: " resultRef

    if [[ -z $resultRef ]]; then
      resultRef=1
      return
    fi

    if [[ $resultRef =~ ^[0-9]+([.][0-9]+)?$ ]]; then
      return
    fi

    logError 'Please enter a numeric scale value.'
  done
}

SetupServices () {
  logInfo 'Enabling required services'

  run sudo systemctl enable --now NetworkManager
  run sudo systemctl enable --now keyd
}

RefreshDesktopDatabase () {
  commandExists update-desktop-database || return

  logInfo 'Refreshing desktop database'
  run update-desktop-database "$HOME/.local/share/applications"
}

ValidateInstallation () {
  local mapping source target desktopFile targetFile

  logInfo 'Validating symlinks and required artifacts'

  for mapping in "${USER_SYMLINKS[@]}"; do
    source=${mapping%%:*}
    target=${mapping#*:}
    EnsureSymlinkMatches "$source" "$target"
  done

  for desktopFile in "$REPO_DIR"/hypr/apps/*.desktop; do
    targetFile="$HOME/.local/share/applications/$(basename "$desktopFile")"
    EnsureSymlinkMatches "$desktopFile" "$targetFile"
  done

  for mapping in "${SYSTEM_SYMLINKS[@]}"; do
    source=${mapping%%:*}
    target=${mapping#*:}
    EnsureSymlinkMatches "$source" "$target"
  done

  if [[ ! -f "$HOME/.config/waybar/hypr-ws-apps/libhypr_ws_apps.so" ]]; then
    logError 'Waybar CFFI module artifact is missing at ~/.config/waybar/hypr-ws-apps/libhypr_ws_apps.so'
    exit 1
  fi

  if ! systemctl is-enabled NetworkManager >/dev/null 2>&1; then
    logError 'NetworkManager service is not enabled.'
    exit 1
  fi

  if ! systemctl is-enabled keyd >/dev/null 2>&1; then
    logError 'keyd service is not enabled.'
    exit 1
  fi

  logInfo 'Installer validation completed successfully'
}

InstallationCompleted () {
  printf "\n\n--- 👼 Installation completed 👼 ---\n"
  printf "\nGo ahead, enjoy the fruits of my labor, you little stupid fucking bitch. Don't forget that you are nobody, you are worthless, you are incapable of an original thought. Amoeba. Your dad would not be proud.\n"
  printf "\nBackups are located in '$BACKUP_DIR', but not like you had anything worthy saving anyway.\n"
  printf "\nRestart your hyprland session to ensure all changes take effect and fuck off.\n"
  printf "\n🖕🖕🖕🖕🖕🖕🖕🖕🖕🖕🖕🖕\n"
}

PromptForHyprlandRestart () {
  local restartOptions=(
    "Waaaah, do everything for me, daddy, restart now, please!"
    "Restart later, I like to play in mud."
  )
  local selectedRestartOption=()

  selectOptions restartOptions selectedRestartOption single true 'Restart Hyprland session now?'

  if [[ ${selectedRestartOption[0]} == 'Waaaah, do everything for me, daddy, restart now, please!' ]]; then
    logInfo 'Restarting Hyprland session now'
    run reboot
    return
  fi

  logInfo 'Skipped Hyprland restart. Restart later to apply all changes.'
}

Cleanup () {
  StopSudoKeepAlive

  [[ -n $TEMP_DIR && -d $TEMP_DIR ]] || return

  logInfo 'Cleaning up temporary files'
  run rm -rf "$TEMP_DIR"
}

BackupTargetIfNeeded () {
  local source=$1
  local target=$2
  local backupPath

  if SymlinkAlreadyMatches "$source" "$target"; then
    return
  fi

  if ! PathExists "$target"; then
    return
  fi

  backupPath="$BACKUP_DIR/${target#/}"
  logInfo "Backing up $target to $backupPath"
  EnsureBackupParentDirectory "$backupPath"

  if IsSystemPath "$target"; then
    run sudo mv "$target" "$backupPath"
  else
    run mv "$target" "$backupPath"
  fi
}

EnsureParentDirectory () {
  local target=$1
  local parentDirectory

  parentDirectory=$(dirname "$target")

  if IsSystemPath "$target"; then
    run sudo mkdir -p "$parentDirectory"
  else
    run mkdir -p "$parentDirectory"
  fi
}

EnsureBackupParentDirectory () {
  local target=$1
  local parentDirectory

  parentDirectory=$(dirname "$target")

  if IsSystemPath "$target"; then
    run sudo mkdir -p "$parentDirectory"
  else
    run mkdir -p "$parentDirectory"
  fi
}

EnsureSymlinkMatches () {
  local source=$1
  local target=$2

  if SymlinkAlreadyMatches "$source" "$target"; then
    return
  fi

  logError "Symlink validation failed for $target"
  exit 1
}

SymlinkAlreadyMatches () {
  local source=$1
  local target=$2
  local sourcePath targetPath

  if ! PathIsSymlink "$target"; then
    return 1
  fi

  sourcePath=$(readlink -f "$source") || return 1

  if IsSystemPath "$target"; then
    targetPath=$(sudo readlink -f "$target") || return 1
  else
    targetPath=$(readlink -f "$target") || return 1
  fi

  [[ $sourcePath == "$targetPath" ]]
}

PathExists () {
  local target=$1

  if IsSystemPath "$target"; then
    sudo test -e "$target" -o -L "$target"
  else
    [[ -e $target || -L $target ]]
  fi
}

PathIsSymlink () {
  local target=$1

  if IsSystemPath "$target"; then
    sudo test -L "$target"
  else
    [[ -L $target ]]
  fi
}

IsSystemPath () {
  [[ $1 == /etc/* ]]
}

commandExists () {
  command -v "$1" >/dev/null 2>&1
}

selectOptions () {
  local optionsRefName=$1
  local resultRefName=$2
  local selectionMode=${3:-multiple}
  local requireSelection=${4:-true}
  local selectionLabel=${5:-}
  local -n optionsRef=$optionsRefName
  local -n resultRef=$resultRefName
  local currentIndex=0
  local footerMessage=''
  local key escapeSequence pointer marker
  local index selectedCount
  local -a selectedStates=()

  if [[ $selectionMode != 'single' && $selectionMode != 'multiple' ]]; then
    logError "Invalid selection mode: $selectionMode"
    exit 1
  fi

  if [[ $requireSelection != 'true' && $requireSelection != 'false' ]]; then
    logError "Invalid requireSelection value: $requireSelection"
    exit 1
  fi

  if [[ ${#optionsRef[@]} -eq 0 ]]; then
    logError 'selectOptions requires at least one option.'
    exit 1
  fi

  resultRef=()

  for ((index = 0; index < ${#optionsRef[@]}; index++)); do
    selectedStates[index]=0
  done

  tput sc

  while true; do
    tput rc
    tput ed

    if [[ -n $selectionLabel ]]; then
      printf '\n%s\n\n' "$selectionLabel"
    fi

    for ((index = 0; index < ${#optionsRef[@]}; index++)); do
      pointer=' '
      marker='○'

      if [[ $index -eq $currentIndex ]]; then
        pointer='>'
      fi

      if [[ $selectionMode == 'single' && $index -eq $currentIndex ]]; then
        marker='●'
      fi

      if [[ $selectionMode == 'multiple' && ${selectedStates[index]} -eq 1 ]]; then
        marker='●'
      fi

      printf '%s %s %s\n' "$pointer" "$marker" "${optionsRef[index]}"
    done

    if [[ -n $footerMessage ]]; then
      printf '\n%s\n' "$footerMessage"
    fi

    IFS= read -rsn1 key

    case "$key" in
      '')
        if [[ $selectionMode == 'single' ]]; then
          resultRef=("${optionsRef[currentIndex]}")
          printf '\n'
          return
        fi

        selectedCount=0
        for index in "${selectedStates[@]}"; do
          ((selectedCount += index))
        done

        if (( selectedCount == 0 )) && [[ $requireSelection == 'false' ]]; then
          printf '\n'
          return
        fi

        if (( selectedCount > 0 )); then
          resultRef=()
          for ((index = 0; index < ${#optionsRef[@]}; index++)); do
            if [[ ${selectedStates[index]} -eq 1 ]]; then
              resultRef+=("${optionsRef[index]}")
            fi
          done

          printf '\n'
          return
        fi

        footerMessage='Select at least one option before continuing.'
        ;;
      ' ')
        if [[ $selectionMode == 'multiple' ]]; then
          if [[ ${selectedStates[currentIndex]} -eq 1 ]]; then
            selectedStates[currentIndex]=0
          else
            selectedStates[currentIndex]=1
          fi
          footerMessage=''
        fi
        ;;
      $'\x1b')
        IFS= read -rsn2 -t 0.05 escapeSequence || continue

        case "$escapeSequence" in
          '[A')
            currentIndex=$(((currentIndex - 1 + ${#optionsRef[@]}) % ${#optionsRef[@]}))
            ;;
          '[B')
            currentIndex=$(((currentIndex + 1) % ${#optionsRef[@]}))
            ;;
        esac
        ;;
    esac
  done
}

promptForValue () {
  local promptMessage=$1
  local -n valueRef=$2

  printf '%s' "> $promptMessage"
  read -r valueRef
}

promptForPackageList () {
  local promptMessage=$1
  local -n resultRef=$2
  local packageInput=''

  resultRef=()
  printf '%s' "> $promptMessage"
  read -r packageInput

  [[ -z $packageInput ]] && return

  read -r -a resultRef <<< "$packageInput"
}

BuildUniquePackageList () {
  local -n resultRef=$1
  shift

  local package
  local -A seenPackages=()

  resultRef=()

  for package in "$@"; do
    [[ -n $package ]] || continue

    if [[ -n ${seenPackages[$package]:-} ]]; then
      continue
    fi

    seenPackages[$package]=1
    resultRef+=("$package")
  done
}

run() {
  printf '> %s\n' "$*"
  "$@" || {
    logError "command failed: $*"
    Cleanup
    exit 1
  }
}

logInfo() {
  printf '%s\n' "[INFO]: $*"
}

logError() {
  printf '\033[31m%s\033[0m\n' "[ERROR]: $*"
}

trap Cleanup EXIT

start