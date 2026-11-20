import CoreGraphics
import Foundation

/// A saved snapshot of a single display's settings.
struct DisplayProfile: Codable {
    var width: Int
    var height: Int
    var refreshRate: Double
    var isHiDPI: Bool
    var brightness: Double?   // 0–1, nil if the display's brightness isn't controllable
}

/// Saves and restores per-display resolution/refresh/brightness, keyed by a stable
/// display UUID so profiles survive reboots and reconnects.
enum ProfileManager {
    private static let profilesKey = "displayProfiles"
    private static let restoreKey  = "restoreProfilesAtLogin"

    /// Whether saved profiles are reapplied automatically at launch.
    static var restoreEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: restoreKey) }
        set { UserDefaults.standard.set(newValue, forKey: restoreKey) }
    }

    /// A stable identifier for a display (survives reconnects/reboots), unlike the
    /// transient `CGDirectDisplayID`. Built from vendor/model/serial numbers.
    private static func stableKey(for id: CGDirectDisplayID) -> String? {
        let vendor = CGDisplayVendorNumber(id)
        let model  = CGDisplayModelNumber(id)
        let serial = CGDisplaySerialNumber(id)
        let builtin = CGDisplayIsBuiltin(id) == 1 ? "builtin" : "external"
        return "\(builtin)-\(vendor)-\(model)-\(serial)"
    }

    private static func loadProfiles() -> [String: DisplayProfile] {
        guard let data = UserDefaults.standard.data(forKey: profilesKey),
              let decoded = try? JSONDecoder().decode([String: DisplayProfile].self, from: data) else { return [:] }
        return decoded
    }

    private static func saveProfiles(_ profiles: [String: DisplayProfile]) {
        guard let data = try? JSONEncoder().encode(profiles) else { return }
        UserDefaults.standard.set(data, forKey: profilesKey)
    }

    /// Captures the current resolution/refresh/brightness of every active display.
    /// May block on DDC for external monitors, so call it off the main thread.
    static func saveCurrent() {
        var profiles = loadProfiles()
        for display in DisplayManager.activeDisplays() {
            guard let key = stableKey(for: display.id),
                  let mode = CGDisplayCopyDisplayMode(display.id) else { continue }
            profiles[key] = DisplayProfile(
                width: mode.width,
                height: mode.height,
                refreshRate: mode.refreshRate,
                isHiDPI: mode.pixelWidth > mode.width,
                brightness: BrightnessManager.getBrightness(for: display.id)
            )
        }
        saveProfiles(profiles)
    }

    /// Reapplies saved profiles to any connected display that has one. Safe at launch.
    static func restoreOnLaunch() {
        let profiles = loadProfiles()
        guard !profiles.isEmpty else { return }

        for display in DisplayManager.activeDisplays() {
            guard let key = stableKey(for: display.id), let profile = profiles[key] else { continue }

            let modes = ResolutionManager.modes(for: display.id)
            let target = modes.first { mode -> Bool in
                let sizeMatches: Bool = mode.width == profile.width && mode.height == profile.height
                let hidpiMatches: Bool = mode.isHiDPI == profile.isHiDPI
                let rateMatches: Bool = profile.refreshRate == 0 || mode.refreshRate == profile.refreshRate
                return sizeMatches && hidpiMatches && rateMatches
            }
            if let target {
                ResolutionManager.setMode(target, for: display.id)
            }

            if let brightness = profile.brightness {
                let id = display.id
                DispatchQueue.global(qos: .userInitiated).async {
                    BrightnessManager.setBrightness(brightness, for: id)
                }
            }
        }
    }
}
