import AppKit

final class StatusBarController: NSObject {
    private let statusItem: NSStatusItem
    private let popover: NSPopover

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        popover = NSPopover()
        super.init()

        if let button = statusItem.button {
            button.action = #selector(togglePopover)
            button.target = self
        }
        updateStatusIcon()

        // Keep the menu bar icon in sync as displays are connected/disconnected.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(displaysChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        // Force loadView now so preferredContentSize is set before first show
        let vc = PopoverViewController()
        _ = vc.view
        popover.contentViewController = vc
        popover.behavior = .transient
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func displaysChanged() {
        updateStatusIcon()
    }

    /// Updates the status-bar icon and badge to reflect the number of connected displays.
    private func updateStatusIcon() {
        guard let button = statusItem.button else { return }
        let count = DisplayManager.activeDisplays().count
        let symbol = count > 1 ? "display.2" : "display"
        let description = "ScreenBoss — \(count) display\(count == 1 ? "" : "s")"
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: description)
        image?.isTemplate = true
        button.image = image

        // Show the exact count alongside the icon when more than one display is present.
        if count > 1 {
            button.title = " \(count)"
            button.imagePosition = .imageLeading
        } else {
            button.title = ""
            button.imagePosition = .imageOnly
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            // Accessory (LSUIElement) apps aren't active on status-item click, so a
            // transient popover dismisses immediately. Activate so it stays up and takes focus.
            popover.contentViewController?.view.window?.makeKey()
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
