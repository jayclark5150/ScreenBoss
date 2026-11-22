import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        LaunchAtLoginManager.enableOnFirstLaunchIfInstalled()
        statusBarController = StatusBarController()

        // Reapply saved per-display settings if the user opted in.
        if ProfileManager.restoreEnabled {
            ProfileManager.restoreOnLaunch()
        }

        // Start global brightness hotkeys if the user enabled them.
        if HotKeyManager.isEnabled {
            HotKeyManager.start()
        }
    }
}
