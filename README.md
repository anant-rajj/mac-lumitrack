# Ultra-Lightweight Command + Trackpad Keyboard Backlight Controller

An ultra-minimal macOS utility that adjusts your MacBook keyboard backlight using the **`Command (⌘)` + Trackpad Drag** shortcut.

---

## 1. Specifications & Metrics

- **Binary Size**: ~50 KB (Compiled native Mach-O binary)
- **RAM Usage**: ~2.5 MB RSS
- **CPU Usage**: 0.0% idle (Event-driven via `CFRunLoop`)
- **Dependencies**: Zero external dependencies (uses native Apple frameworks `CoreGraphics`, `MultitouchSupport` & `CoreBrightness`)
- **Zero Accidental Triggers**: When `Command (⌘)` is not held down, the trackpad functions 100% normally (clicks, cursor movement, two-finger scroll, three-finger swipe, pinch zoom are completely untouched).

---

## 2. Gesture Mapping

| Action | Shortcut | Direction |
| :--- | :--- | :--- |
| **Increase Keyboard Brightness** | Hold **`Command (⌘)`** + 1 finger on lower trackpad | Slide **Left to Right** |
| **Decrease Keyboard Brightness** | Hold **`Command (⌘)`** + 1 finger on lower trackpad | Slide **Right to Left** |
| **Normal macOS usage** | Regular trackpad touches (without `Command`) | 100% untouched & passed through |
| **Multi-touch gestures** | 2, 3, or 4 fingers | Completely untouched & passed through |

---

## 3. Project Structure

```
/Users/anantraj/trackpad-kb-brightness/
├── main.m                  # Core source code (Objective-C/C)
├── Makefile                # Build configuration (clang -O3 -fobjc-arc)
├── trackpad-kb-brightness  # Compiled stripped binary (50 KB)
└── README.md               # Documentation & usage instructions
```

---

## 4. macOS Permissions

Requires permissions in **System Settings** → **Privacy & Security**:
1. **Accessibility**
2. **Input Monitoring** (for Terminal)

---

## 5. How to Run

Run with verbose logging enabled to see real-time updates:

```bash
cd /Users/anantraj/trackpad-kb-brightness
./trackpad-kb-brightness --verbose
```

To run in the background permanently:

```bash
cd /Users/anantraj/trackpad-kb-brightness
./trackpad-kb-brightness > /dev/null 2>&1 &
```

To stop at any time:
```bash
killall trackpad-kb-brightness
```
