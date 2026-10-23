# mac-lumitrack

### Ultra-Lightweight Trackpad Keyboard Backlight Controller for macOS

An ultra-lightweight, zero-dependency native macOS background daemon written in pure C/Objective-C that adjusts your MacBook keyboard backlight brightness via **`Command (⌘)` or `Fn` (Globe) + Trackpad drag**.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: macOS](https://img.shields.io/badge/Platform-macOS-lightgrey.svg)](https://apple.com)
[![Binary Size: ~50KB](https://img.shields.io/badge/Binary%20Size-~50KB-green.svg)]()
[![Memory: ~3.5MB](https://img.shields.io/badge/RAM%20Footprint-~3.5MB-green.svg)]()

---

## 1. Quick Installation (For Anyone on macOS)

Clone and start the background daemon on your Mac in one step:

```bash
git clone https://github.com/anant-rajj/mac-lumitrack.git
cd mac-lumitrack
make start
```

That's it! The tool is now running quietly in the background.

> **Permissions Note**: If prompted on first run, grant **Accessibility** permissions in `System Settings -> Privacy & Security -> Accessibility`.

---

## 2. Gesture Mapping

| Action | Gesture | Direction |
| :--- | :--- | :--- |
| **Increase Keyboard Brightness** | Hold **`Command (⌘)`** or **`Fn`** + 1 finger on lower trackpad | Slide **Left → Right** |
| **Decrease Keyboard Brightness** | Hold **`Command (⌘)`** or **`Fn`** + 1 finger on lower trackpad | Slide **Right → Left** |
| **Normal macOS usage** | Regular touches (without modifier key held) | **100% untouched & passed through** |
| **Multi-touch gestures** | 2, 3, or 4 fingers (scrolling, mission control, swipes) | **Completely untouched** |

---

## 3. Background Controls & Auto-Start

### Manage Background Process
```bash
make status   # Check if currently running and view PID
make stop     # Stop the background daemon
make start    # Restart the background daemon
```

### Auto-Start 24/7 on Login (Optional)
To have macOS start it automatically every time you log in (survives reboots, no terminal needed):
```bash
make install-service
```

To remove the auto-start service:
```bash
make uninstall-service
```

---

## 4. Debug Mode
To inspect real-time touch coordinates and brightness percentage values live in your terminal:
```bash
./mac-lumitrack --verbose
```

---

## 5. Specifications & Architecture
- **Binary Size**: ~50 KB (Stripped native Mach-O executable)
- **RAM Footprint**: ~3.5 MB RSS
- **CPU Idle**: 0.0% (Zero polling; event-driven via `MultitouchSupport` contact callbacks)
- **Zero External Dependencies**: Links directly to Apple's native frameworks (`CoreGraphics`, `MultitouchSupport`, `CoreBrightness`).
- **Auto-Brightness Override**: Automatically turns off macOS ambient sensor throttling so manual keyboard brightness control works even in bright rooms.

---

## 6. Uninstallation & Complete Removal

To stop all background daemons, disable auto-start, and completely remove `mac-lumitrack`:

### Option 1: Via Makefile
From inside the repository directory:
```bash
make stop
make uninstall-service
```

### Option 2: Manual Removal & Cleanup
To ensure all running daemons, services, and downloaded files are completely removed:
```bash
# 1. Stop background processes and unload LaunchAgent
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.anantraj.mac-lumitrack.plist 2>/dev/null || true
pkill -9 -f "mac-lumitrack" || true
rm -f /tmp/mac-lumitrack.pid

# 2. Remove the installed binary and LaunchAgent configuration
rm -f ~/.local/bin/mac-lumitrack
rm -f ~/Library/LaunchAgents/com.anantraj.mac-lumitrack.plist

# 3. Delete the repository directory
rm -rf ~/mac-lumitrack
```
