import AppKit

final class PopoverViewController: NSViewController {

    private var sliderMap:        [NSSlider: CGDirectDisplayID]      = [:]
    private var popupMap:         [NSPopUpButton: CGDirectDisplayID] = [:]
    private var modesMap:         [CGDirectDisplayID: [DisplayMode]] = [:]
    private var hzPopupMap:       [NSPopUpButton: CGDirectDisplayID] = [:]
    private var trueToneMap:      [NSButton: CGDirectDisplayID]      = [:]
    private var brightnessSliders: [CGDirectDisplayID: NSSlider]     = [:]

    override func loadView() {
        NSLog("ScreenBoss: loadView START")
        let v = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 10))
        view = v

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: v.topAnchor, constant: 14),
            stack.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: v.bottomAnchor, constant: -14),
            v.widthAnchor.constraint(equalToConstant: 300),
        ])

        let header = NSTextField(labelWithString: "ScreenBoss")
        header.font = .boldSystemFont(ofSize: 13)
        stack.addArrangedSubview(header)
        addSeparator(to: stack)

        let displays = DisplayManager.activeDisplays()
        for (i, display) in displays.enumerated() {
            let card = displayCard(for: display)
            stack.addArrangedSubview(card)
            // Must be added to the hierarchy before constraining to a sibling of its ancestor.
            NSLayoutConstraint.activate([card.widthAnchor.constraint(equalTo: stack.widthAnchor)])
            if i < displays.count - 1 { addSeparator(to: stack) }
        }

        addSeparator(to: stack)

        let nsRow = NSStackView()
        nsRow.orientation = .horizontal
        nsRow.alignment = .centerY
        nsRow.spacing = 6
        let nsLabel = NSTextField(labelWithString: "Night Shift")
        nsLabel.font = .systemFont(ofSize: 12)
        nsLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let nsToggle = NSButton(checkboxWithTitle: "", target: self, action: #selector(nightShiftToggled(_:)))
        nsToggle.state = NightShiftManager.isEnabled ? .on : .off
        nsRow.addArrangedSubview(nsLabel)
        nsRow.addArrangedSubview(nsToggle)
        stack.addArrangedSubview(nsRow)
        NSLayoutConstraint.activate([nsRow.widthAnchor.constraint(equalTo: stack.widthAnchor)])

        addSeparator(to: stack)

        let buttonRow = NSStackView()
        buttonRow.orientation = .horizontal
        buttonRow.alignment = .centerY
        buttonRow.spacing = 8

        let prefsBtn = NSButton(title: "Preferences…", target: self, action: #selector(openPreferences))
        prefsBtn.bezelStyle = .rounded
        prefsBtn.controlSize = .small

        let quitBtn = NSButton(title: "Quit ScreenBoss", target: NSApp,
                               action: #selector(NSApplication.terminate(_:)))
        quitBtn.bezelStyle = .rounded
        quitBtn.controlSize = .small

        buttonRow.addArrangedSubview(prefsBtn)
        buttonRow.addArrangedSubview(quitBtn)
        stack.addArrangedSubview(buttonRow)

        v.layoutSubtreeIfNeeded()
        let fit = v.fittingSize
        preferredContentSize = fit.height > 10 ? fit : NSSize(width: 300, height: 200)

        // Fetch brightness values off the main thread to avoid blocking on DDC I2C
        for display in displays {
            fetchBrightnessAsync(displayID: display.id)
        }
    }

    // MARK: - Display card

    private func displayCard(for display: DisplayInfo) -> NSView {
        let card = NSStackView()
        card.orientation = .vertical
        card.alignment = .leading
        card.spacing = 6

        let nameLabel = NSTextField(labelWithString: display.name + (display.isMain ? "  •" : ""))
        nameLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        card.addArrangedSubview(nameLabel)

        var parts: [String] = ["\(display.nativeWidth) × \(display.nativeHeight)"]
        if display.scaleFactor > 1 { parts.append("@\(Int(display.scaleFactor))× Retina") }
        if display.refreshRate > 0 { parts.append("\(Int(display.refreshRate)) Hz") }
        let detailLabel = NSTextField(labelWithString: parts.joined(separator: "  ·  "))
        detailLabel.font = .systemFont(ofSize: 11)
        detailLabel.textColor = .secondaryLabelColor
        card.addArrangedSubview(detailLabel)

        // Build brightness row immediately with a placeholder; value filled in async
        let brightnessRow = buildBrightnessRow(displayID: display.id)
        card.addArrangedSubview(brightnessRow)
        NSLayoutConstraint.activate([brightnessRow.widthAnchor.constraint(equalTo: card.widthAnchor)])

        let modes = ResolutionManager.modes(for: display.id)
        if !modes.isEmpty {
            let row = resolutionRow(displayID: display.id, modes: modes)
            card.addArrangedSubview(row)
            NSLayoutConstraint.activate([row.widthAnchor.constraint(equalTo: card.widthAnchor)])
        }

        let rates = ResolutionManager.availableRefreshRates(for: display.id)
        if rates.count > 1 {
            let row = refreshRateRow(displayID: display.id, rates: rates)
            card.addArrangedSubview(row)
            NSLayoutConstraint.activate([row.widthAnchor.constraint(equalTo: card.widthAnchor)])
        }

        if TrueToneManager.isSupported(for: display.id) {
            card.addArrangedSubview(trueToneRow(displayID: display.id))
        }

        return card
    }

    // MARK: - Async brightness

    private func fetchBrightnessAsync(displayID: CGDirectDisplayID) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let value = BrightnessManager.getBrightness(for: displayID)
            DispatchQueue.main.async {
                guard let self else { return }
                if let slider = self.brightnessSliders[displayID] {
                    if let v = value {
                        slider.doubleValue = v
                        slider.isHidden = false
                    } else {
                        slider.isHidden = true
                    }
                }
            }
        }
    }

    // MARK: - Row builders

    private func buildBrightnessRow(displayID: CGDirectDisplayID) -> NSView {
        let row = iconRow(icon: "sun.max.fill")
        let slider = NSSlider(value: 0.5, minValue: 0.01, maxValue: 1.0,
                              target: self, action: #selector(brightnessChanged(_:)))
        slider.isContinuous = true
        slider.controlSize = .small
        slider.setContentHuggingPriority(.defaultLow, for: .horizontal)
        slider.isHidden = true  // shown when async fetch completes
        sliderMap[slider] = displayID
        brightnessSliders[displayID] = slider
        (row as! NSStackView).addArrangedSubview(slider)
        return row
    }

    private func resolutionRow(displayID: CGDirectDisplayID, modes: [DisplayMode]) -> NSView {
        let row = iconRow(icon: "rectangle.3.group")
        let popup = NSPopUpButton(frame: .zero, pullsDown: false)
        popup.controlSize = .small
        popup.font = .systemFont(ofSize: 11)
        popup.setContentHuggingPriority(.defaultLow, for: .horizontal)
        for mode in modes { popup.addItem(withTitle: mode.label) }
        modesMap[displayID] = modes
        popupMap[popup] = displayID
        popup.selectItem(at: ResolutionManager.currentModeIndex(for: displayID, in: modes))
        popup.target = self
        popup.action = #selector(resolutionChanged(_:))
        (row as! NSStackView).addArrangedSubview(popup)
        return row
    }

    private func refreshRateRow(displayID: CGDirectDisplayID, rates: [Double]) -> NSView {
        let row = iconRow(icon: "arrow.clockwise")
        let popup = NSPopUpButton(frame: .zero, pullsDown: false)
        popup.controlSize = .small
        popup.font = .systemFont(ofSize: 11)
        popup.setContentHuggingPriority(.defaultLow, for: .horizontal)
        for hz in rates { popup.addItem(withTitle: "\(Int(hz)) Hz") }
        let currentHz = CGDisplayCopyDisplayMode(displayID)?.refreshRate ?? 0
        if let idx = rates.firstIndex(of: currentHz) { popup.selectItem(at: idx) }
        hzPopupMap[popup] = displayID
        popup.target = self
        popup.action = #selector(refreshRateChanged(_:))
        (row as! NSStackView).addArrangedSubview(popup)
        return row
    }

    private func trueToneRow(displayID: CGDirectDisplayID) -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 6
        let icon = iconView("circle.lefthalf.filled.righthalf.striped.horizontal.inverse")
        let label = NSTextField(labelWithString: "True Tone")
        label.font = .systemFont(ofSize: 11)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let btn = NSButton(checkboxWithTitle: "", target: self, action: #selector(trueToneToggled(_:)))
        btn.state = TrueToneManager.isEnabled(for: displayID) ? .on : .off
        trueToneMap[btn] = displayID
        row.addArrangedSubview(icon)
        row.addArrangedSubview(label)
        row.addArrangedSubview(btn)
        return row
    }

    private func iconRow(icon symbolName: String) -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 6
        row.addArrangedSubview(iconView(symbolName))
        return row
    }

    private func iconView(_ symbolName: String) -> NSView {
        let img = NSImageView()
        img.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)
        img.contentTintColor = .tertiaryLabelColor
        img.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            img.widthAnchor.constraint(equalToConstant: 14),
            img.heightAnchor.constraint(equalToConstant: 14),
        ])
        return img
    }

    private func addSeparator(to stack: NSStackView) {
        let sep = NSBox()
        sep.boxType = .separator
        sep.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(sep)
        NSLayoutConstraint.activate([sep.widthAnchor.constraint(equalTo: stack.widthAnchor)])
    }

    // MARK: - Actions

    @objc private func brightnessChanged(_ sender: NSSlider) {
        guard let id = sliderMap[sender] else { return }
        let value = sender.doubleValue
        DispatchQueue.global(qos: .userInitiated).async {
            BrightnessManager.setBrightness(value, for: id)
        }
    }

    @objc private func resolutionChanged(_ sender: NSPopUpButton) {
        guard let id = popupMap[sender], let modes = modesMap[id] else { return }
        let idx = sender.indexOfSelectedItem
        guard idx >= 0, idx < modes.count else { return }
        ResolutionManager.setMode(modes[idx], for: id)
    }

    @objc private func refreshRateChanged(_ sender: NSPopUpButton) {
        guard let id = hzPopupMap[sender] else { return }
        if let hz = Double(sender.titleOfSelectedItem?.replacingOccurrences(of: " Hz", with: "") ?? "") {
            ResolutionManager.setRefreshRate(hz, for: id)
        }
    }

    @objc private func nightShiftToggled(_ sender: NSButton) {
        NightShiftManager.setEnabled(sender.state == .on)
    }

    @objc private func openPreferences() {
        PreferencesWindowController.shared.show()
    }

    @objc private func trueToneToggled(_ sender: NSButton) {
        guard let id = trueToneMap[sender] else { return }
        TrueToneManager.setEnabled(sender.state == .on, for: id)
    }
}
