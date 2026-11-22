import AppKit
import ServiceManagement

/// Controls whether ScreenBoss starts automatically at login.
///
/// Uses `SMAppService.mainApp` (macOS 13+), which registers the app itself as a
/// login item — no separate helper target required. Both the popover's
/// "Open at Login" checkbox and the Preferences window go through here.
enum LaunchAtLoginManager {
    private static let didAutoEnableKey = "didAutoEnableLoginItem"

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Registered, but waiting for approval in System Settings → General → Login Items.
    static var needsApproval: Bool {
        SMAppService.mainApp.status == .requiresApproval
    }

    /// What a checkbox should show: on when enabled or awaiting approval.
    static var isOnOrPending: Bool { isEnabled || needsApproval }

    /// Enables or disables launch-at-login. Returns `false` if the change failed.
    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Bool {
        let service = SMAppService.mainApp
        do {
            if enabled {
                if service.status != .enabled { try service.register() }
            } else {
                if service.status == .enabled || service.status == .requiresApproval {
                    try service.unregister()
                }
            }
            return true
        } catch {
            NSLog("ScreenBoss: launch-at-login \(enabled ? "register" : "unregister") failed: \(error.localizedDescription)")
            return false
        }
    }

    /// Handles a checkbox click: applies the change and, if macOS wants the user to
    /// approve it, opens the Login Items pane in System Settings.
    static func userToggled(_ enabled: Bool) {
        setEnabled(enabled)
        if enabled && needsApproval {
            SMAppService.openSystemSettingsLoginItems()
        }
    }

    /// Turns on launch-at-login the first time the app runs from /Applications.
    /// Skipped for builds run from elsewhere, so a login item never points at a build folder.
    static func enableOnFirstLaunchIfInstalled() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: didAutoEnableKey) else { return }
        guard Bundle.main.bundlePath.hasPrefix("/Applications/") else { return }
        defaults.set(true, forKey: didAutoEnableKey)
        if !isEnabled { setEnabled(true) }
    }
}
