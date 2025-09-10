# Bazzite-OpenGamepadUI Build Instructions

## Quick Build

1. Fork this repository to your GitHub account
2. Enable GitHub Actions in your fork
3. Push any commit to trigger the build
4. Download the resulting ISO from the Actions artifacts

## Manual Build

```bash
# Clone the repository
git clone https://github.com/your-username/bazzite-opengamepadui.git
cd bazzite-opengamepadui

# Build using Podman/Docker
podman build -t bazzite-opengamepadui .

# Create and flash the image
podman run --rm --privileged -v /dev:/dev bazzite-opengamepadui
```

## What Gets Built

This creates a complete handheld gaming OS with:

- **Base**: Bazzite-deck (optimized for handheld gaming)
- **Interface**: OpenGamepadUI instead of Steam
- **Features**: 
  - Automatic login to gaming session
  - Optimized for handheld devices
  - InputPlumber for advanced controller support
  - PowerStation for performance management
  - Gamescope compositor
  - Multi-platform game library support

## First Boot

1. Flash the ISO to a USB drive or SD card
2. Boot your handheld device from the installation media
3. Follow the standard Fedora installation process
4. On first boot, you'll be logged in automatically to OpenGamepadUI
5. Configure your game libraries (Steam, Epic, GOG, etc.)

## Session Switching

You can switch between sessions using:
```bash
steamos-session-select desktop  # Switch to desktop
steamos-session-select opengamepadui  # Switch back to gaming
```

## Troubleshooting

- If OpenGamepadUI doesn't start, check: `journalctl -u opengamepadui-session`
- For display issues, verify Gamescope is running: `ps aux | grep gamescope`
- For controller issues, check InputPlumber: `systemctl status inputplumber`

## Customization

Edit `build_files/build.sh` to modify the installation process.
Edit `opengamepadui-handheld.conf` to change default settings.
