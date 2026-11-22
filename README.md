# ScreenBoss

A lightweight macOS menu bar app for quick control of your displays: brightness,
resolution, refresh rate, True Tone, and Night Shift — all from a single popover.
It also starts at login, adjusts brightness from the keyboard, and can restore your
per-display settings automatically.

Requires macOS 13 Ventura or later.

## Install

1. Download the latest `ScreenBoss-x.y.z.dmg` from the
   [Releases](https://github.com/jayclark5150/ScreenBoss/releases) page.
2. Open it and drag **ScreenBoss** into **Applications**.
3. Launch it from Applications. Its icon appears in the menu bar (there's no Dock icon).

> The app is ad-hoc signed (no Apple Developer ID), so the first time you launch it
> macOS Gatekeeper will block it. Right-click the app → **Open**, then confirm. You
> only need to do this once.

The first time ScreenBoss runs from Applications it adds itself to your login items,
so it starts automatically from then on. Untick **Open at Login** in the popover to
turn that off.

## Features

- Per-display **brightness** control (including DDC/CI for external monitors)
- **Resolution** switching
- **Refresh rate** switching
- **True Tone** toggle (on supported displays)
- **Night Shift** toggle
- **Open at Login**, on by default, toggled from the popover or Preferences
- **Keyboard shortcuts** for brightness (⌃⌥↑ / ⌃⌥↓, opt-in)
- **Per-display profiles**: save each display's resolution, refresh rate, and brightness
  and restore them at login
- **Preferences window** for the settings above
- Menu bar icon **reflects the number of connected displays**
- Runs as a menu bar accessory (no Dock icon)

## Preferences

Open the popover and click **Preferences…** to:

- Toggle **Launch at login**
- Enable the **brightness keyboard shortcuts** (⌃⌥↑ / ⌃⌥↓)
- Enable **Restore display settings at login**, and click **Save Current Settings as
  Profile** to snapshot each display's current resolution, refresh rate, and brightness

### If it doesn't start at login

macOS sometimes needs you to approve a login item. Open **System Settings → General →
Login Items** and make sure ScreenBoss is listed and switched on. If it isn't listed,
click **+** under *Open at Login* and choose ScreenBoss from Applications.

## Build from source

Requires Xcode (from the App Store, opened once) and
[XcodeGen](https://github.com/yonaskolb/XcodeGen).

```sh
brew install xcodegen
xcodegen generate
xcodebuild -project ScreenBoss.xcodeproj -scheme ScreenBoss -configuration Release \
  -derivedDataPath build CODE_SIGN_IDENTITY="-" build
cp -R build/Build/Products/Release/ScreenBoss.app /Applications/
```

The project is defined in `project.yml`; the `.xcodeproj` is generated and not
checked in. Run `xcodegen generate` again whenever you add or remove source files.
The app icon's source is `Design/AppIcon.svg`.

## Releasing

Bump `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in `project.yml`, add a section
to `CHANGELOG.md`, then push a tag:

```sh
git tag v1.2.0 && git push origin v1.2.0
```

The **Release** GitHub Action builds the app, packages `ScreenBoss-x.y.z.dmg`, and
publishes a GitHub release using that version's notes from `CHANGELOG.md`.

## License

[MIT](LICENSE) © Jay Clark
