import AppKit

/// A small settings window hosting app-wide preferences: launch at login,
/// brightness hotkeys, and display-profile restore.
final class PreferencesWindowController: NSWindowController {

    static let shared = PreferencesWindowController()

    private var launchToggle: NSButton!
    private var hotkeyToggle: NSButton!
    private var restoreToggle: NSButton!

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 240),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "ScreenBoss Preferences"
        window.isReleasedWhenClosed = false
        super.init(window: window)
        buildUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Brings the window forward, refreshing control states from the managers first.
    func show() {
        syncControls()
        NSApp.activate(ignoringOtherApps: true)
        window?.center()
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }

    private func buildUI() {
        guard let content = window?.contentView else { return }

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
        ])

        stack.addArrangedSubview(sectionLabel("General"))
        launchToggle = NSButton(checkboxWithTitle: "Launch ScreenBoss at login",
                                target: self, action: #selector(launchToggled(_:)))
        stack.addArrangedSubview(launchToggle)

        stack.addArrangedSubview(spacer())
        stack.addArrangedSubview(sectionLabel("Keyboard Shortcuts"))
        hotkeyToggle = NSButton(checkboxWithTitle: "Adjust brightness with ⌃⌥↑ / ⌃⌥↓",
                                target: self, action: #selector(hotkeyToggled(_:)))
        stack.addArrangedSubview(hotkeyToggle)

        stack.addArrangedSubview(spacer())
        stack.addArrangedSubview(sectionLabel("Display Profiles"))
        restoreToggle = NSButton(checkboxWithTitle: "Restore display settings at login",
                                 target: self, action: #selector(restoreToggled(_:)))
        stack.addArrangedSubview(restoreToggle)

        let saveButton = NSButton(title: "Save Current Settings as Profile",
                                  target: self, action: #selector(saveProfile(_:)))
        saveButton.bezelStyle = .rounded
        saveButton.controlSize = .small
        stack.addArrangedSubview(saveButton)
    }

    private func syncControls() {
        launchToggle.state  = LaunchAtLoginManager.isOnOrPending ? .on : .off
        hotkeyToggle.state  = HotKeyManager.isEnabled ? .on : .off
        restoreToggle.state = ProfileManager.restoreEnabled ? .on : .off
    }

    private func sectionLabel(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = .boldSystemFont(ofSize: 12)
        return label
    }

    private func spacer() -> NSView {
        let v = NSView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: 4).isActive = true
        return v
    }

    // MARK: - Actions

    @objc private func launchToggled(_ sender: NSButton) {
        LaunchAtLoginManager.userToggled(sender.state == .on)
        sender.state = LaunchAtLoginManager.isOnOrPending ? .on : .off
    }

    @objc private func hotkeyToggled(_ sender: NSButton) {
        HotKeyManager.isEnabled = (sender.state == .on)
    }

    @objc private func restoreToggled(_ sender: NSButton) {
        ProfileManager.restoreEnabled = (sender.state == .on)
    }

    @objc private func saveProfile(_ sender: NSButton) {
        let originalTitle = sender.title
        sender.isEnabled = false
        sender.title = "Saving…"
        DispatchQueue.global(qos: .userInitiated).async {
            ProfileManager.saveCurrent()
            DispatchQueue.main.async {
                sender.title = "Saved ✓"
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    sender.title = originalTitle
                    sender.isEnabled = true
                }
            }
        }
    }
}
