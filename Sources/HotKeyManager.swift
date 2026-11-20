import AppKit
import Carbon.HIToolbox

/// Global keyboard shortcuts for brightness, using Carbon `RegisterEventHotKey`
/// (works without Accessibility permission and consumes the key event).
///
/// Defaults: ⌃⌥↑ raises and ⌃⌥↓ lowers brightness on all controllable displays.
enum HotKeyManager {
    private static var upRef: EventHotKeyRef?
    private static var downRef: EventHotKeyRef?
    private static var handlerRef: EventHandlerRef?

    private static let step = 1.0 / 16.0
    private static let enabledKey = "brightnessHotkeysEnabled"
    private static let signature: OSType = 0x53424853  // 'SBHS'
    private static let upID: UInt32 = 1
    private static let downID: UInt32 = 2

    /// Persisted on/off state. Setting it starts or stops the hotkeys immediately.
    static var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: enabledKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: enabledKey)
            if newValue { start() } else { stop() }
        }
    }

    static func start() {
        guard handlerRef == nil else { return }

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ -> OSStatus in
            var hkID = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject),
                              EventParamType(typeEventHotKeyID), nil,
                              MemoryLayout<EventHotKeyID>.size, nil, &hkID)
            HotKeyManager.handle(hkID.id)
            return noErr
        }, 1, &eventType, nil, &handlerRef)

        let mods = UInt32(controlKey | optionKey)
        register(keyCode: UInt32(kVK_UpArrow), id: upID, mods: mods, ref: &upRef)
        register(keyCode: UInt32(kVK_DownArrow), id: downID, mods: mods, ref: &downRef)
    }

    static func stop() {
        if let up = upRef { UnregisterEventHotKey(up); upRef = nil }
        if let down = downRef { UnregisterEventHotKey(down); downRef = nil }
        if let handler = handlerRef { RemoveEventHandler(handler); handlerRef = nil }
    }

    private static func register(keyCode: UInt32, id: UInt32, mods: UInt32, ref: inout EventHotKeyRef?) {
        let hotKeyID = EventHotKeyID(signature: signature, id: id)
        RegisterEventHotKey(keyCode, mods, hotKeyID, GetApplicationEventTarget(), 0, &ref)
    }

    /// Applies a brightness delta to every controllable display. Runs off the main
    /// thread because DDC I/O for external monitors can block.
    fileprivate static func handle(_ id: UInt32) {
        let delta = (id == upID) ? step : -step
        DispatchQueue.global(qos: .userInitiated).async {
            for display in DisplayManager.activeDisplays() {
                guard let current = BrightnessManager.getBrightness(for: display.id) else { continue }
                BrightnessManager.setBrightness(current + delta, for: display.id)
            }
        }
    }
}
