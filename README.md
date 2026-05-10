# NeonFocus

A tiny macOS menu-bar utility that draws a pulsing hot-pink neon halo around
whichever **Apple Terminal** window currently has keyboard focus.

```
┌──────────┐  ┌──────────┐  ┌──────────┐
│ api      │  │ dotfiles │  │ notes    │   ← three Terminal windows
│ npm dev  │  │ vim      │  │ tail -f  │
└──────────┘  └━━━━━━━━━━┘  └──────────┘
                  ▲
                  └── hot-pink pulsing halo around the focused one
```

## Status

v0.1 — Apple Terminal only. Single hardcoded variation.

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

## First-run permission

NeonFocus needs **Accessibility** permission to read the focused Terminal
window's frame. On first launch, macOS will prompt you. If you miss it:

> System Settings → Privacy & Security → Accessibility → enable **NeonFocus**

No screen-recording or input-monitoring permissions are required.

## What it does

- Lives in the menu bar as a `circle.dashed` icon. Menu: **Enable / Quit**.
- When **Apple Terminal** is the frontmost app, it watches focus changes via
  the Accessibility API (`kAXFocusedWindowChangedNotification`,
  `kAXMovedNotification`, `kAXResizedNotification`).
- A transparent click-through `NSPanel` follows the focused window's frame and
  renders a 1.6s ease-in-out neon-pink pulse via Core Animation.
- When you `⌘-Tab` to anything other than Terminal, the overlay hides.

## Architecture (one screen)

```
NeonFocusApp ──► AppDelegate ──► FocusCoordinator ──┬── ActiveAppMonitor ──► NSWorkspace
                                                    ├── AccessibilityPermissions
                                                    ├── AXFocusTracker ──► AXObserver
                                                    ├── OverlayController ──► OverlayPanel
                                                    │                         └── NeonPulseView
                                                    └── StatusMenuController ──► NSStatusItem
```

## Known limitations

- **Apple Terminal only.** iTerm / Ghostty / Warp can be added by extending
  `ActiveAppMonitor.terminalBundleID` to a set; left out of v0.1 by design.
- **No transition burst.** The wireframe's "focus-handoff burst" is not yet
  implemented — focus changes snap.
- **No preferences.** Color, pulse speed, and thickness are hardcoded.
- **Not signed.** Local debug builds run under ad-hoc signing; distribution
  via Homebrew cask requires a Developer ID + notarization (see
  `design-bundle/chats/chat1.md` for the path).

