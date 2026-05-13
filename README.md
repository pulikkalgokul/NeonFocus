# NeonFocus

A tiny macOS menu-bar utility that draws a configurable neon halo around
whichever selected terminal app window currently has keyboard focus.

<img width="1107" height="676" alt="Screenshot 2026-05-10 at 8 57 27 PM" src="https://github.com/user-attachments/assets/c110ed75-57e1-4584-aee2-f7dd6a72409a" />

```
┌──────────┐  ┌──────────┐  ┌──────────┐
│ api      │  │ dotfiles │  │ notes    │   ← terminal app windows
│ npm dev  │  │ vim      │  │ tail -f  │
└──────────┘  └━━━━━━━━━━┘  └──────────┘
                  ▲
                  └── pulsing neon halo around the focused one
```

## Status

v0.1.0 — curated terminal-app support with menu-bar controls for app selection,
color, thickness, pulse speed, glow intensity, and focus-burst vibration.

## Install

```bash
brew install --cask pulikkalgokul/tap/neonfocus
```

That's it — Homebrew downloads the notarized build from the [latest
release](https://github.com/pulikkalgokul/NeonFocus/releases) and installs it
into `/Applications`. Launch it from Spotlight or `/Applications/NeonFocus.app`.

To update later: `brew upgrade --cask neonfocus`.

## Build from source

### Prerequisites

- macOS 14+
- Xcode 16+ (the project was generated against Xcode 26.3)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

### Build & run

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

### Cutting a release

The release pipeline (Developer ID signing → Apple notarization → stapling →
GitHub release → cask bump in [the tap repo](https://github.com/pulikkalgokul/homebrew-tap))
is run from a maintainer's machine and is not part of the public source tree.
See `scripts/ExportOptions.plist` for the export config used.

## First-run permission

NeonFocus needs **Accessibility** permission to read the focused terminal
window's frame. On first launch, macOS will prompt you. If you miss it:

> System Settings → Privacy & Security → Accessibility → enable **NeonFocus**

No screen-recording or input-monitoring permissions are required.

## What it does

- Lives in the menu bar as a `circle.dashed` icon.
- Provides an enable toggle, terminal-app selection, overlay style submenus,
  and **Quit NeonFocus**.
- When a selected terminal app is frontmost, it watches focus changes via the
  Accessibility API (`kAXFocusedWindowChangedNotification`,
  `kAXMovedNotification`, `kAXResizedNotification`).
- A transparent click-through `NSPanel` follows the focused window's frame and
  renders a Core Animation neon pulse with an outer edge-fade glow.
- Plays a short focus-burst vibration when focus moves to a different terminal
  window.
- Persists the enable state, selected terminal apps, and overlay settings in
  `UserDefaults`.
- When you `⌘-Tab` to anything other than a selected terminal app, the overlay
  hides.

## Menu settings

- **Color:** Hot Pink, Electric Cyan, Acid Green
- **Thickness:** Slim, Regular, Bold
- **Pulse Speed:** Slow, Normal, Fast
- **Glow:** Subtle, Bright, Vivid
- **Vibration:** Focus Burst, Off
- **Terminal Apps:** Apple Terminal, iTerm2, Ghostty, Warp, Warp Preview,
  WezTerm, kitty, Alacritty

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

- **Curated terminal apps only.** Arbitrary app selection is intentionally not
  exposed; new terminal apps should be added to the curated list after AX
  behavior validation.
