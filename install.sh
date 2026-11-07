#!/bin/bash
# ============================================================
#  Hyprland installation script for Debian
#  Hyprland + hyprpm + dotfiles
# ============================================================

set -e

TEMP_DIR="$HOME/.debian_hypr_temp"

log()  { printf '\033[1;32m[+]\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$1"; }
die()  { printf '\033[1;31m[x]\033[0m %s\n' "$1"; exit 1; }

cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        log "Cleaning up temp directory: $TEMP_DIR"
        rm -rf "$TEMP_DIR"
    fi
}
trap cleanup EXIT

mkdir -p "$TEMP_DIR"
log "Created temp directory: $TEMP_DIR"

# ──────────────────────────────────────────────────────────
# 1. Update the system
# ──────────────────────────────────────────────────────────
log "Upgrading system..."
sudo apt update || warn "apt update failed — revisa tu conexión o repositorios."
sudo apt upgrade -y || warn "System upgrade failed — complétalo manualmente y vuelve a ejecutar el script."

# ──────────────────────────────────────────────────────────
# 2. Hyprland and base packages
# ──────────────────────────────────────────────────────────
log "Installing Hyprland and base packages..."
sudo apt install -y \
    hyprland xwayland \
    alacritty waybar swaybg swaync fuzzel \
    wvkbd jq brightnessctl \
    swaylock fonts-font-awesome fonts-jetbrains-mono neofetch \
    kitty xdg-desktop-portal xdg-desktop-portal-gtk \
    xdg-desktop-portal-hyprland

# On Debian, chmod +s is usually NOT needed for brightnessctl.
# If brightnessctl does not work without sudo, check the udev permissions
# instead of forcing it.

# Detect the version installed by APT
HYPRLAND_VERSION="$(dpkg-query -W -f='${Version}' hyprland 2>/dev/null | sed -E 's/^[0-9]+:([0-9]+\.[0-9]+\.[0-9]+).*/v\1/')"

if [ -z "$HYPRLAND_VERSION" ]; then
    die "No se pudo detectar la versión de Hyprland. ¿Está instalado el paquete 'hyprland'?"
fi

log "Detected Hyprland version: $HYPRLAND_VERSION"

# ──────────────────────────────────────────────────────────
# 3. xdg-desktop-portal configuration
# ──────────────────────────────────────────────────────────
log "Creating xdg-desktop-portal config..."
mkdir -p "$HOME/.config/xdg-desktop-portal"
printf '[preferred]\ndefault=hyprland;gtk\norg.freedesktop.impl.portal.FileChooser=gtk\n' \
    > "$HOME/.config/xdg-desktop-portal/portals.conf"

# ──────────────────────────────────────────────────────────
# 4. Dependencies to build hyprpm / plugins
# ──────────────────────────────────────────────────────────
log "Installing hyprpm build dependencies..."
sudo apt install -y \
    git cmake ninja-build make g++ meson cpio pkg-config python3 \
    libwayland-dev wayland-protocols \
    libinput-dev libxkbcommon-dev libxkbcommon-x11-dev \
    libdrm-dev libgbm-dev libegl-dev libglx-dev libglvnd-dev \
    libpango1.0-dev libcairo2-dev libpixman-1-dev \
    libxcb1-dev libxcb-util-dev libxcb-util-wm-dev \
    libxcb-ewmh-dev libxcb-icccm4-dev libxcb-render-util0-dev \
    libxcb-xkb-dev libxcursor-dev \
    libudev-dev libseat-dev \
    libglm-dev libglibmm-2.4-dev libpulse-dev \
    libtomlplusplus-dev libpugixml-dev \
    hyprland-dev

# ──────────────────────────────────────────────────────────
# 5. Build hyprwire only if it is missing
# ──────────────────────────────────────────────────────────
if ! pkg-config --modversion hyprwire > /dev/null 2>&1; then
    log "hyprwire pkg-config not found — building from source..."
    cd "$TEMP_DIR"
    git clone https://github.com/hyprwm/hyprwire
    cd hyprwire
    cmake -B build -DCMAKE_BUILD_TYPE=Release
    cmake --build build -j"$(nproc)"
    sudo cmake --install build
    cd "$TEMP_DIR"
fi

# ──────────────────────────────────────────────────────────
# 6. Clone Hyprland and build hyprpm
# ──────────────────────────────────────────────────────────
log "Cloning Hyprland source... ($HYPRLAND_VERSION)"
cd "$TEMP_DIR"

RESOLV_BACKUP="$(cat /etc/resolv.conf)"

git clone https://github.com/hyprwm/Hyprland || {
    warn "git clone failed — setting DNS to 8.8.8.8 and retrying..."
    printf 'nameserver 8.8.8.8\n' | sudo tee /etc/resolv.conf > /dev/null
    git clone https://github.com/hyprwm/Hyprland || die "git clone failed even after DNS change"
    printf '%s\n' "$RESOLV_BACKUP" | sudo tee /etc/resolv.conf > /dev/null
    log "DNS restored"
}

cd Hyprland

# The APT version may include Debian suffixes; use the upstream tag if it exists.
git checkout "$HYPRLAND_VERSION" 2>/dev/null || {
    warn "Could not checkout $HYPRLAND_VERSION — using current main branch."
    git checkout main
}

git submodule update --init --recursive

log "Building hyprpm..."
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --target hyprpm -j"$(nproc)"

log "Installing hyprpm..."
sudo cmake --install build --component hyprpm

if ! command -v hyprpm > /dev/null 2>&1; then
    warn "hyprpm not in PATH — copying to /usr/local/bin..."
    sudo cp "$TEMP_DIR/Hyprland/build/hyprpm/hyprpm" /usr/local/bin/
    sudo chmod +x /usr/local/bin/hyprpm
fi

export PATH="/usr/local/bin:$PATH"
command -v hyprpm > /dev/null 2>&1 || die "hyprpm installation failed"
log "hyprpm installed successfully"

# ──────────────────────────────────────────────────────────
# 7. Download and apply dotfiles
# ──────────────────────────────────────────────────────────
log "Downloading dotfiles..."
cd "$TEMP_DIR"

git clone https://github.com/commander-Z3R0/HyprLand-arm64/ repo || {
    warn "Failed to clone repo — please copy dotfiles manually."
}

if [ -d "$TEMP_DIR/repo/installer/config" ]; then
    mkdir -p "$HOME/.config"
    cp -r "$TEMP_DIR/repo/installer/config/." "$HOME/.config/"
    log "Dotfiles applied → ~/.config/"

    for script in \
        "$HOME/.config/hypr/scripts/install_hyprgrass.sh" \
        "$HOME/.config/hypr/scripts/screenshot.sh" \
        "$HOME/.config/hypr/scripts/toggle_rotate.sh"; do
        [ -f "$script" ] && chmod +x "$script"
    done
fi

# ──────────────────────────────────────────────────────────
# End
# ──────────────────────────────────────────────────────────
log "========================================"
log "Installation complete!"
log ""
log "Reboot after 5 seconds and select Hyprland at the login screen."
log ""
log "[hyprgrass] On your first Hyprland boot,"
log "hyprgrass will be installed automatically"
log "for touch gesture support."
log "========================================"

sleep 5
sudo reboot
