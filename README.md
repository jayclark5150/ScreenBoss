# ScreenBoss

A lightweight macOS menu bar app for quick control of your displays: brightness,
resolution, refresh rate, True Tone, and Night Shift — all from a single popover.
It can also launch at login, adjust brightness from the keyboard, and restore your
per-display settings automatically.

## Install

Download the latest `ScreenBoss-x.y.z.dmg` from the
[Releases](https://github.com/jayclark5150/ScreenBoss/releases) page, open it, and
drag **ScreenBoss** into **Applications**.

> The app is ad-hoc signed (no Apple Developer ID), so the first time you launch it
> macOS Gatekeeper will block it. Right-click the app → **Open**, then confirm. You
> only need to do this once.

## Features

- Per-display **brightness** control (including DDC/CI for external monitors)
- **Resolution** switching
- **Refresh rate** switching
- **True Tone** toggle (on supported displays)
- **Night Shift** toggle
- **Keyboard shortcuts** for brightness (⌃⌥↑ / ⌃⌥↓, opt-in)
- **Per-display profiles** — save your resolution/refresh/brightness and restore them at login
- **Launch at login** (via `SMAppService`)
- **Preferences window** for the above settings
- Menu bar icon **reflects the number of connected displays**
- Runs as a menu bar accessory (no Dock icon)

## Preferences

Open the popover and click **Preferences…** to:

- Toggle **Launch at login**
- Enable the **brightness keyboard shortcuts** (⌃⌥↑ / ⌃⌥↓)
- Enable **Restore display settings at login**, and **Save Current Settings as Profile**
  to snapshot each display's current resolution, refresh rate, and brightness

## Build from source

Requires [XcodeGen](https://github.com/yonaskolb/XcodeGen) and Xcode command line tools.

```sh
brew install xcodegen
xcodegen generate
xcodebuild -project ScreenBoss.xcodeproj -scheme ScreenBoss -configuration Release build
```

The project is defined in `project.yml`; the `.xcodeproj` is generated and not
checked in.

## License

[MIT](LICENSE) © Jay Clark
