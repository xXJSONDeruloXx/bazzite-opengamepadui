# Bazzite-OpenGamepadUI Build Instructions

## GitHub Actions Setup (Automated Building)

### 1. Initial Repository Setup
Your GitHub Actions workflows are already configured! Here's what you need to do:

1. **Enable GitHub Actions**: Go to your repository → Actions tab → Enable workflows
2. **Set up Container Registry**: Actions will automatically use GitHub Container Registry (ghcr.io)
3. **Add Signing Secret**: 
   - Copy the content of `cosign.key` (the private key file in your repo)
   - Go to your repository → Settings → Secrets and variables → Actions
   - Create a new secret named `SIGNING_SECRET`
   - Paste the private key content as the value

### 2. Automatic Builds
Your image will automatically build when you:
- Push to the `main` branch 
- Create a pull request
- Trigger manually via Actions tab
- Daily at 10:05 AM UTC (scheduled)

### 3. Built Images
After a successful build, your image will be available at:
```
ghcr.io/xxjsonderuloxx/bazzite-opengamepadui:latest
```

### 4. Disk Images (ISO/QCOW2)
To build installable disk images:
1. Go to Actions tab in your repository
2. Select "Build disk images" workflow
3. Click "Run workflow" 
4. Choose platform (amd64/arm64) and upload options
5. Download artifacts when complete

## Local Build (Development)

```bash
# Clone the repository
git clone https://github.com/xxjsonderuloxx/bazzite-opengamepadui.git
cd bazzite-opengamepadui

# Build using Podman
just build

# Or build disk images locally
just build-iso    # For installation ISO
just build-qcow2  # For VM testing
```

## Installation & Usage

### Installing on Hardware
1. Go to your repository's Actions tab
2. Run "Build disk images" workflow to create an ISO
3. Download the ISO from the artifacts
4. Flash to USB drive using tools like:
   - Fedora Media Writer
   - Balena Etcher  
   - `dd` command on Linux
5. Boot from USB and install

### Installing on Existing System
If you're already running a bootc-compatible system (Bazzite, Bluefin, etc.):
```bash
sudo bootc switch ghcr.io/xxjsonderuloxx/bazzite-opengamepadui:latest
sudo reboot
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

1. On first boot, you'll be logged in automatically to OpenGamepadUI
2. Configure your game libraries (Steam, Epic, GOG, etc.)
3. Enjoy your handheld gaming experience!

## Session Switching

You can switch between sessions using:
```bash
steamos-session-select desktop        # Switch to desktop
steamos-session-select opengamepadui  # Switch back to gaming
```

## Troubleshooting

### Build Issues
- Check the Actions tab for build logs
- Ensure `SIGNING_SECRET` is properly set in repository secrets
- Verify disk config files point to your repository

### Runtime Issues  
- If OpenGamepadUI doesn't start: `journalctl -u opengamepadui-session`
- For display issues: `ps aux | grep gamescope`
- For controller issues: `systemctl status inputplumber`

### Updates
To update your system:
```bash
sudo bootc update
sudo reboot
```

To rollback if there are issues:
```bash
sudo bootc rollback
sudo reboot
```

## Customization

- Edit `build_files/build.sh` to modify the installation process
- Edit `opengamepadui-handheld.conf` to change default settings
- Modify `Containerfile` to change the base image or build process
