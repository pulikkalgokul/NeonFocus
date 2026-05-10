# NeonFocus

A tiny macOS menu-bar utility that draws a configurable neon halo around
whichever **Apple Terminal** window currently has keyboard focus.

```
┌──────────┐  ┌──────────┐  ┌──────────┐
│ api      │  │ dotfiles │  │ notes    │   ← three Terminal windows
│ npm dev  │  │ vim      │  │ tail -f  │
└──────────┘  └━━━━━━━━━━┘  └──────────┘
                  ▲
                  └── pulsing neon halo around the focused one
```

## Status

v0.1.0 — Apple Terminal support with menu-bar controls for color, thickness,
pulse speed, glow intensity, and focus-burst vibration.

## Prerequisites

- macOS 14+
- Xcode 16+ (the project was generated against Xcode 26.3)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

## Build & run

```bash
cd ShowFocus
xcodegen generate
open NeonFocus.xcodeproj
# In Xcode: select the NeonFocus scheme and ⌘R
```

Or from the command line:

```bash
xcodegen generate
xcodebuild -project NeonFocus.xcodeproj -scheme NeonFocus -configuration Debug build
open build/Debug/NeonFocus.app
```

The Xcode project is **not committed**; regenerate it with `xcodegen generate`
any time you change `project.yml`.

Run the unit tests with:

```bash
xcodebuild -project NeonFocus.xcodeproj -scheme NeonFocus -destination "platform=macOS,arch=$(uname -m)" test
```

## First-run permission

NeonFocus needs **Accessibility** permission to read the focused Terminal
window's frame. On first launch, macOS will prompt you. If you miss it:

> System Settings → Privacy & Security → Accessibility → enable **NeonFocus**

No screen-recording or input-monitoring permissions are required.

## What it does

- Lives in the menu bar as a `circle.dashed` icon.
- Provides an enable toggle, overlay style submenus, and **Quit NeonFocus**.
- When **Apple Terminal** is the frontmost app, it watches focus changes via
  the Accessibility API (`kAXFocusedWindowChangedNotification`,
  `kAXMovedNotification`, `kAXResizedNotification`).
- A transparent click-through `NSPanel` follows the focused window's frame and
  renders a Core Animation neon pulse with an outer edge-fade glow.
- Plays a short focus-burst vibration when focus moves to a different Terminal
  window.
- Persists the enable state and overlay settings in `UserDefaults`.
- When you `⌘-Tab` to anything other than Terminal, the overlay hides.

## Menu settings

- **Color:** Hot Pink, Electric Cyan, Acid Green
- **Thickness:** Slim, Regular, Bold
- **Pulse Speed:** Slow, Normal, Fast
- **Glow:** Subtle, Bright, Vivid
- **Vibration:** Focus Burst, Off

## Architecture (one screen)

```
NeonFocusApp ──► AppDelegate ──► FocusCoordinator ──┬── ActiveAppMonitor ──► NSWorkspace
                                                    ├── AccessibilityPermissions
                                                    ├── AXFocusTracker ──► AXObserver
                                                    ├── NeonFocusSettingsStore ──► UserDefaults
                                                    ├── OverlayController ──► OverlayPanel
                                                    │                         └── NeonPulseView ──► NeonPulseAnimationSpec
                                                    └── StatusMenuController ──► NSStatusItem
```

## Known limitations

- **Apple Terminal only.** iTerm, Ghostty, and Warp support would need bundle-ID
  matching plus AX behavior validation for each app.
- **Not signed.** Local debug builds run under ad-hoc signing; distribution
  via Homebrew cask requires a Developer ID + notarization (see
  `design-bundle/chats/chat1.md` for the path).
