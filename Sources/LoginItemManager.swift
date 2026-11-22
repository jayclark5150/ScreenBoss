import AppKit
import ServiceManagement

/// Registers ScreenBoss as a login item so it starts automatically when you log in.
enum LoginItemManager {
    private static let didAutoEnableKey = "didAutoEnableLoginItem"

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Needs the user to approve it in System Settings → General → Login Items.
    static var needsApproval: Bool {
        SMAppService.mainApp.status == .requiresApproval
    }

    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Bool {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return true
        } catch {
            NSLog("ScreenBoss: login item \(enabled ? "register" : "unregister") failed: \(error)")
            return false
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

    static func openLoginItemsSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
