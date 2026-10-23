# Ultra-Lightweight Trackpad Keyboard Backlight Controller

An ultra-lightweight, zero-dependency native macOS background daemon written in pure C/Objective-C that adjusts your MacBook keyboard backlight brightness via **`Command (⌘)` or `Fn` (Globe) + Trackpad drag**.

## 1. Specifications & Metrics
- **Binary Size**: ~50 KB (Compiled stripped native Mach-O binary)
- **RAM Footprint**: ~3.5 MB RSS
- **Idle CPU**: 0.0% (Fully event-driven via `MultitouchSupport` run loop)
- **Dependencies**: Zero external runtimes (uses native Apple frameworks `CoreGraphics`, `MultitouchSupport` & `CoreBrightness`)
- **Zero Accidental Triggers**: Normal trackpad gestures (clicks, cursor movement, two-finger scroll, three-finger swipe, pinch zoom) are 100% unaffected when neither `Command` nor `Fn` is pressed.

---

## 2. Gesture Mapping
| Action | Shortcut | Direction |
| :--- | :--- | :--- |
| **Increase Keyboard Brightness** | Hold **`Command (⌘)`** or **`Fn`** + 1 finger on lower trackpad | Slide **Left to Right** |
| **Decrease Keyboard Brightness** | Hold **`Command (⌘)`** or **`Fn`** + 1 finger on lower trackpad | Slide **Right to Left** |
| **Normal macOS usage** | Regular touches (without modifier held) | 100% untouched & passed through |
| **Multi-touch gestures** | 2, 3, or 4 fingers | Completely untouched & passed through |

---

## 3. Running in the Background (Survives Terminal Closure)

### Method A: Quick Background Daemon (Recommended)
To run detached from your terminal session so it never dies when closing or escaping Terminal:
```bash
cd /Users/anantraj/trackpad-kb-brightness
make start
```
- Forks into the background as an independent daemon.
- Ignores `SIGHUP` and `SIGPIPE` — **closing, exiting, or killing Terminal will NOT stop it**.
- Logs real-time status to `/tmp/trackpad-kb-brightness.log`.

To check status or stop it:
```bash
make status  # Shows running PID
make stop    # Stops the background daemon cleanly
```

---

### Method B: 24/7 macOS LaunchAgent (Starts on Login)
To have it run permanently in the background without ever needing to open a terminal:
```bash
cd /Users/anantraj/trackpad-kb-brightness
make install-service
```
- Registers `~/Library/LaunchAgents/com.anantraj.trackpad-kb-brightness.plist`.
- macOS launches it automatically on user login and keeps it alive.

To uninstall:
```bash
make uninstall-service
```

---

## 4. Manual / Debug Mode
If you want to view real-time touch coordinate and brightness percentage logs in the terminal:
```bash
cd /Users/anantraj/trackpad-kb-brightness
./trackpad-kb-brightness --verbose
```
