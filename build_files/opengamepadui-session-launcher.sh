#!/bin/bash

# Bazzite-OpenGamepadUI Session Launcher
# This script properly initializes the gaming environment and launches OpenGamepadUI

set -e

# Set up logging
exec > >(logger -t opengamepadui-session) 2>&1

echo "Starting Bazzite-OpenGamepadUI gaming session..."

# Set up environment variables for gaming
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=gamescope
export XDG_SESSION_DESKTOP=gamescope
export QT_QPA_PLATFORM=wayland
export GDK_BACKEND=wayland
export SDL_VIDEODRIVER=wayland
export WAYLAND_DISPLAY=wayland-0

# Gaming performance optimizations
export GAMESCOPE_ARGS="--xwayland-count=2 -w 1920 -h 1080 --adaptive-sync --mangoapp"
export MESA_LOADER_DRIVER_OVERRIDE=radeonsi
export RADV_PERFTEST=gpl

# Set up directories
mkdir -p "$HOME/.config/opengamepadui"
mkdir -p "$HOME/.local/share/opengamepadui"
mkdir -p "$HOME/.cache/opengamepadui"

# Copy default configuration if it doesn't exist
if [ ! -f "$HOME/.config/opengamepadui/settings.conf" ]; then
    if [ -f "/etc/opengamepadui/handheld.conf" ]; then
        cp "/etc/opengamepadui/handheld.conf" "$HOME/.config/opengamepadui/settings.conf"
    fi
fi

# Ensure required services are running
systemctl --user start inputplumber.service || echo "Warning: InputPlumber not available"
systemctl --user start powerstation.service || echo "Warning: PowerStation not available"

# Wait a moment for services to initialize
sleep 2

# Function to check if gamescope is already running
is_gamescope_running() {
    pgrep -x gamescope >/dev/null 2>&1
}

# Function to launch OpenGamepadUI
launch_opengamepadui() {
    echo "Launching OpenGamepadUI..."
    
    # If gamescope is not running, start it with OpenGamepadUI
    if ! is_gamescope_running; then
        echo "Starting Gamescope compositor..."
        exec gamescope \
            --xwayland-count=2 \
            -w 1920 -h 1080 \
            --adaptive-sync \
            --mangoapp \
            --force-grab-cursor \
            -- /usr/bin/opengamepadui "$@"
    else
        echo "Gamescope already running, starting OpenGamepadUI in existing session..."
        exec /usr/bin/opengamepadui "$@"
    fi
}

# Function to handle cleanup on exit
cleanup() {
    echo "Gaming session ending..."
    # Kill any remaining gaming processes
    pkill -f opengamepadui || true
    pkill -f gamescope || true
}

# Set up signal handlers
trap cleanup EXIT INT TERM

# Launch the gaming session
launch_opengamepadui "$@"
