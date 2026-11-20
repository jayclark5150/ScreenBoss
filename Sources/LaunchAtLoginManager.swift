import ServiceManagement

/// Controls whether ScreenBoss starts automatically at login.
///
/// Uses `SMAppService.mainApp` (macOS 13+), which registers the app itself as a
/// login item — no separate helper target required.
enum LaunchAtLoginManager {

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Enables or disables launch-at-login. Returns `false` if the change failed
    /// (e.g. the user denied it in System Settings → General → Login Items).
    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Bool {
        let service = SMAppService.mainApp
        do {
            if enabled {
                if service.status != .enabled { try service.register() }
            } else {
                if service.status == .enabled { try service.unregister() }
            }
            return true
        } catch {
            NSLog("ScreenBoss: launch-at-login \(enabled ? "register" : "unregister") failed: \(error.localizedDescription)")
            return false
        }
    }
}
