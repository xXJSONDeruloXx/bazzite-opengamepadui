#!/bin/bash

set -ouex pipefail

echo "Building Bazzite-OpenGamepadUI: A handheld gaming OS with OpenGamepadUI"

### Install OpenGamepadUI and Dependencies

# Install required dependencies (skip already installed)
echo "Installing required dependencies..."
dnf5 install -y --skip-unavailable \
    curl \
    wget \
    unzip \
    systemd \
    polkit \
    dbus \
    gamescope \
    vulkan-tools \
    make

# Install InputPlumber for advanced input management (if available)
echo "Checking for InputPlumber availability..."
if dnf5 copr enable -y shadowblip/inputplumber 2>/dev/null; then
    echo "Installing InputPlumber from COPR..."
    dnf5 install -y --skip-unavailable inputplumber || echo "InputPlumber not available, skipping..."
else
    echo "InputPlumber COPR not available for this Fedora version, skipping..."
fi

# Install PowerStation for performance management (if available)  
echo "Checking for PowerStation availability..."
if dnf5 copr enable -y shadowblip/powerstation 2>/dev/null; then
    echo "Installing PowerStation from COPR..."
    dnf5 install -y --skip-unavailable powerstation || echo "PowerStation not available, skipping..."
else
    echo "PowerStation COPR not available for this Fedora version, skipping..."
fi

# Download and install OpenGamepadUI using binary installation
echo "Installing OpenGamepadUI from binary release..."

# Create temporary directory for installation
mkdir -p /tmp/opengamepadui-build
cd /tmp/opengamepadui-build

# Download the latest binary release
echo "Downloading OpenGamepadUI binary release..."
curl -L "https://github.com/ShadowBlip/OpenGamepadUI/releases/latest/download/opengamepadui.tar.gz" -o opengamepadui.tar.gz

# Verify download succeeded
if [ ! -f opengamepadui.tar.gz ]; then
    echo "ERROR: Failed to download OpenGamepadUI"
    exit 1
fi

# Extract and install using the recommended method
echo "Extracting and installing OpenGamepadUI..."
tar xvfz opengamepadui.tar.gz
cd opengamepadui

# Install system-wide as recommended in the documentation
make install PREFIX=/usr || {
    echo "ERROR: OpenGamepadUI installation failed"
    exit 1
}

# Clean up temporary build directory
cd /
rm -rf /tmp/opengamepadui-build

### Configure OpenGamepadUI as the primary gaming interface

echo "Configuring OpenGamepadUI services..."

# Create systemd user service for OpenGamepadUI session
mkdir -p /etc/systemd/user
cat > /etc/systemd/user/opengamepadui-session.service << 'EOF'
[Unit]
Description=OpenGamepadUI Gaming Session
After=graphical-session.target
Wants=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/opengamepadui
Restart=always
RestartSec=3
Environment=XDG_SESSION_TYPE=wayland
Environment=XDG_CURRENT_DESKTOP=gamescope
Environment=WAYLAND_DISPLAY=wayland-0

[Install]
WantedBy=default.target
EOF

# Create desktop session for OpenGamepadUI
mkdir -p /usr/share/wayland-sessions
cat > /usr/share/wayland-sessions/opengamepadui.desktop << 'EOF'
[Desktop Entry]
Name=OpenGamepadUI
Comment=Gaming interface powered by OpenGamepadUI
Exec=/usr/bin/opengamepadui
Type=Application
DesktopNames=gamescope
EOF

# Create OpenGamepadUI session script
mkdir -p /usr/bin
cp /ctx/opengamepadui-session-launcher.sh /usr/bin/opengamepadui-session
chmod +x /usr/bin/opengamepadui-session

# Also create a direct launcher
cat > /usr/bin/opengamepadui-handheld << 'EOF'
#!/bin/bash
# Direct OpenGamepadUI launcher for handheld devices
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=gamescope
exec gamescope --xwayland-count=2 -w 1920 -h 1080 --adaptive-sync --force-grab-cursor -- /usr/bin/opengamepadui "$@"
EOF

chmod +x /usr/bin/opengamepadui-handheld

### Configure automatic login and session startup

echo "Configuring automatic login to OpenGamepadUI..."

# Create gaming user account (only add to groups that exist)
useradd -m -s /bin/bash -G wheel gamer || true

# Set up automatic login for the gaming user
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << 'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty -o '-p -f -- \\u' --noclear --autologin gamer %I $TERM
EOF

# Ensure home directory exists and create user session configuration
mkdir -p /home/gamer/.config/systemd/user
cat > /home/gamer/.config/systemd/user/opengamepadui-autostart.service << 'EOF'
[Unit]
Description=Auto-start OpenGamepadUI
After=graphical-session.target
Wants=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/opengamepadui-session
Restart=always
RestartSec=5
Environment=DISPLAY=:0

[Install]
WantedBy=default.target
EOF

# Set up the gamer user environment
chown -R gamer:gamer /home/gamer/.config || true

# Configure user to auto-start OpenGamepadUI session
mkdir -p /home/gamer/.config/environment.d
mkdir -p /etc/opengamepadui
cp /ctx/opengamepadui-handheld.conf /etc/opengamepadui/handheld.conf

cat > /home/gamer/.config/environment.d/gaming.conf << 'EOF'
# Gaming environment configuration
XDG_SESSION_TYPE=wayland
XDG_CURRENT_DESKTOP=gamescope
QT_QPA_PLATFORM=wayland
GDK_BACKEND=wayland
SDL_VIDEODRIVER=wayland
GAMESCOPE_ARGS=--xwayland-count=2 -w 1920 -h 1080 --adaptive-sync --force-grab-cursor
EOF

# Fix ownership of all user files
chown -R gamer:gamer /home/gamer || true

### Enable required services

echo "Enabling system services..."

# Enable essential services (only if they exist)
systemctl enable inputplumber || echo "InputPlumber service not available"
systemctl enable powerstation || echo "PowerStation service not available"
systemctl enable dbus || true
systemctl enable systemd-logind || true

# Configure polkit permissions for gaming user
cat > /etc/polkit-1/rules.d/50-opengamepadui.rules << 'EOF'
// Allow gamer user to manage system services needed for gaming
polkit.addRule(function(action, subject) {
    if (subject.user == "gamer") {
        if (action.id == "org.freedesktop.systemd1.manage-units" ||
            action.id == "org.freedesktop.NetworkManager.settings.modify.system" ||
            action.id == "org.freedesktop.NetworkManager.network-control" ||
            action.id == "org.shadowblip.manage_input" ||
            action.id == "org.shadowblip.setcap") {
            return polkit.Result.YES;
        }
    }
});
EOF

### Configure desktop environment

echo "Configuring desktop environment for gaming..."

# Set default session to OpenGamepadUI
mkdir -p /var/lib/AccountsService/users
cat > /var/lib/AccountsService/users/gamer << 'EOF'
[User]
Language=
XSession=opengamepadui
SystemAccount=false
EOF

### Optimize for handheld gaming

echo "Applying handheld gaming optimizations..."

# Configure udev rules for handheld devices
cat > /etc/udev/rules.d/99-handheld-gaming.rules << 'EOF'
# Handheld gaming device optimizations
# Steam Deck controls
SUBSYSTEM=="input", ATTRS{name}=="Steam Deck Controller", MODE="0664", GROUP="input"
# Generic handheld controls  
SUBSYSTEM=="input", ATTRS{name}=="*Gamepad*", MODE="0664", GROUP="input"
SUBSYSTEM=="input", ATTRS{name}=="*Controller*", MODE="0664", GROUP="input"
# Power management for handheld devices
SUBSYSTEM=="power_supply", ATTR{type}=="Battery", GROUP="power"
EOF

# Configure kernel parameters for gaming performance
cat > /etc/sysctl.d/99-gaming-performance.conf << 'EOF'
# Gaming performance optimizations
vm.max_map_count=2147483642
vm.swappiness=1
kernel.sched_cfs_bandwidth_slice_us=3000
kernel.sched_latency_ns=4000000
EOF

### Clean up Steam components that conflict with OpenGamepadUI

echo "Removing conflicting Steam components..."

# Remove Steam autostart if it exists
rm -f /etc/systemd/user/steam-deck.service || true
rm -f /home/gamer/.config/autostart/steam.desktop || true

# Disable Steam session if it exists
systemctl --global disable steam-session@.service || true

### Final configuration

echo "Finalizing OpenGamepadUI gaming OS configuration..."

# Ensure proper ownership
chown -R gamer:gamer /home/gamer

# Create a welcome message
cat > /etc/motd << 'EOF'

 ██████╗ ██████╗ ███████╗███╗   ██╗ ██████╗  █████╗ ███╗   ███╗███████╗██████╗  █████╗ ██████╗ ██╗   ██╗██╗
██╔═══██╗██╔══██╗██╔════╝████╗  ██║██╔════╝ ██╔══██╗████╗ ████║██╔════╝██╔══██╗██╔══██╗██╔══██╗██║   ██║██║
██║   ██║██████╔╝█████╗  ██╔██╗ ██║██║  ███╗███████║██╔████╔██║█████╗  ██████╔╝███████║██║  ██║██║   ██║██║
██║   ██║██╔═══╝ ██╔══╝  ██║╚██╗██║██║   ██║██╔══██║██║╚██╔╝██║██╔══╝  ██╔═══╝ ██╔══██║██║  ██║██║   ██║██║
╚██████╔╝██║     ███████╗██║ ╚████║╚██████╔╝██║  ██║██║ ╚═╝ ██║███████╗██║     ██║  ██║██████╔╝╚██████╔╝██║
 ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝╚═╝     ╚═╝  ╚═╝╚═════╝  ╚═════╝ ╚═╝

Bazzite-OpenGamepadUI: Handheld Gaming OS
Based on Bazzite-deck with OpenGamepadUI interface

EOF

echo "Build complete! Your handheld gaming OS is ready."
