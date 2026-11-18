import AppKit

final class StatusBarController: NSObject {
    private let statusItem: NSStatusItem
    private let popover: NSPopover

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        popover = NSPopover()
        super.init()

        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "display.2", accessibilityDescription: "ScreenBoss")
            image?.isTemplate = true
            button.image = image
            button.action = #selector(togglePopover)
            button.target = self
        }

        // Force loadView now so preferredContentSize is set before first show
        let vc = PopoverViewController()
        _ = vc.view
        popover.contentViewController = vc
        popover.behavior = .transient
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
