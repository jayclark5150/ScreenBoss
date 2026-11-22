# Changelog

## 1.1.0

### New
- **App icon**: a new icon for Finder, Launchpad, and Applications.
- **Open at Login**: ScreenBoss adds itself to your login items the first time it runs
  from Applications. Turn it off with the **Open at Login** checkbox in the popover or
  in Preferences.
- **Preferences window**: click **Preferences…** in the popover.
- **Brightness keyboard shortcuts**: ⌃⌥↑ and ⌃⌥↓ (turn on in Preferences).
- **Per-display profiles**: save each display's resolution, refresh rate, and brightness,
  and restore them automatically at login.
- The menu bar icon now shows how many displays are connected.

### Install
Download `ScreenBoss-1.1.0.dmg`, open it, and drag **ScreenBoss** into **Applications**,
replacing the old copy. Quit the running ScreenBoss first.

The app isn't signed with an Apple Developer ID, so macOS blocks it the first time:

- **macOS 15 Sequoia and later:** open it once, click **Done**, then go to
  **System Settings → Privacy & Security**, scroll to **Security**, and click
  **Open Anyway** next to ScreenBoss.
- **macOS 13–14:** right-click the app → **Open**, then click **Open**.

See the [README](https://github.com/jayclark5150/ScreenBoss#allowing-screenboss-to-open)
for details.

## 1.0.0

First release: brightness, resolution, refresh rate, True Tone, and Night Shift
controls for every display from the menu bar.
