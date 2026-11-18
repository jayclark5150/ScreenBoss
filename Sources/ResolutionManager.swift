import CoreGraphics
import Foundation

struct DisplayMode: Identifiable {
    let id: String          // unique key for dedup
    let cgMode: CGDisplayMode
    let width: Int
    let height: Int
    let pixelWidth: Int
    let pixelHeight: Int
    let refreshRate: Double
    let isHiDPI: Bool

    var label: String {
        let hz  = refreshRate > 0 ? " · \(Int(refreshRate)) Hz" : ""
        let tag = isHiDPI ? " · HiDPI" : ""
        return "\(width) × \(height)\(hz)\(tag)"
    }
}

enum ResolutionManager {

    /// All usable modes for a display, deduplicated and sorted largest-first.
    static func modes(for displayID: CGDirectDisplayID) -> [DisplayMode] {
        let opts = [kCGDisplayShowDuplicateLowResolutionModes: kCFBooleanTrue] as CFDictionary
        guard let raw = CGDisplayCopyAllDisplayModes(displayID, opts) as? [CGDisplayMode] else { return [] }

        var seen = Set<String>()
        var result: [DisplayMode] = []

        for cgMode in raw {
            let w    = cgMode.width
            let h    = cgMode.height
            let pw   = cgMode.pixelWidth
            let ph   = cgMode.pixelHeight
            let hz   = cgMode.refreshRate
            let hiDPI = pw > w || ph > h
            let key  = "\(w)x\(h)@\(Int(hz))_\(hiDPI)"

            guard !seen.contains(key), cgMode.isUsableForDesktopGUI() else { continue }
            seen.insert(key)
            result.append(DisplayMode(id: key, cgMode: cgMode,
                                      width: w, height: h,
                                      pixelWidth: pw, pixelHeight: ph,
                                      refreshRate: hz, isHiDPI: hiDPI))
        }

        return result.sorted {
            if $0.width != $1.width { return $0.width > $1.width }
            if $0.height != $1.height { return $0.height > $1.height }
            return $0.refreshRate > $1.refreshRate
        }
    }

    /// Returns the index in `modes(for:)` that matches the current active mode.
    static func currentModeIndex(for displayID: CGDirectDisplayID, in modes: [DisplayMode]) -> Int {
        guard let active = CGDisplayCopyDisplayMode(displayID) else { return 0 }
        return modes.firstIndex { $0.cgMode == active } ?? 0
    }

    /// Available refresh rates for the display's current resolution, sorted highest-first.
    static func availableRefreshRates(for displayID: CGDirectDisplayID) -> [Double] {
        guard let active = CGDisplayCopyDisplayMode(displayID) else { return [] }
        let w = active.width; let h = active.height
        let hiDPI = active.pixelWidth > active.width
        let rates = modes(for: displayID)
            .filter { $0.width == w && $0.height == h && $0.isHiDPI == hiDPI && $0.refreshRate > 0 }
            .map { $0.refreshRate }
        return Array(Set(rates)).sorted(by: >)
    }

    static func setRefreshRate(_ hz: Double, for displayID: CGDirectDisplayID) {
        guard let active = CGDisplayCopyDisplayMode(displayID) else { return }
        let w = active.width; let h = active.height
        let hiDPI = active.pixelWidth > active.width
        guard let target = modes(for: displayID).first(where: {
            $0.width == w && $0.height == h && $0.isHiDPI == hiDPI && $0.refreshRate == hz
        }) else { return }
        setMode(target, for: displayID)
    }

    /// Applies a mode change for the current login session.
    @discardableResult
    static func setMode(_ mode: DisplayMode, for displayID: CGDirectDisplayID) -> Bool {
        var config: CGDisplayConfigRef?
        guard CGBeginDisplayConfiguration(&config) == .success,
              let cfg = config else { return false }

        let err = CGConfigureDisplayWithDisplayMode(cfg, displayID, mode.cgMode, nil)
        guard err == .success else {
            CGCancelDisplayConfiguration(cfg)
            return false
        }
        return CGCompleteDisplayConfiguration(cfg, .forSession) == .success
    }
}
