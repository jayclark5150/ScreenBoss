import Darwin
import CoreGraphics
import IOKit

enum BrightnessManager {

    // MARK: - CoreDisplay (private framework, works for built-in + some external)

    private static let coreDisplayLib: UnsafeMutableRawPointer? =
        dlopen("/System/Library/PrivateFrameworks/CoreDisplay.framework/CoreDisplay", RTLD_LAZY)

    private static let _cdGet: (@convention(c) (CGDirectDisplayID) -> Double)? = {
        guard let lib = coreDisplayLib, let sym = dlsym(lib, "CoreDisplay_Display_GetUserBrightness") else { return nil }
        return unsafeBitCast(sym, to: (@convention(c) (CGDirectDisplayID) -> Double).self)
    }()

    private static let _cdSet: (@convention(c) (CGDirectDisplayID, Double) -> Void)? = {
        guard let lib = coreDisplayLib, let sym = dlsym(lib, "CoreDisplay_Display_SetUserBrightness") else { return nil }
        return unsafeBitCast(sym, to: (@convention(c) (CGDirectDisplayID, Double) -> Void).self)
    }()

    // MARK: - Public API

    /// Returns current brightness 0–1, or nil if uncontrollable.
    static func getBrightness(for displayID: CGDirectDisplayID) -> Double? {
        // Built-in: CoreDisplay is authoritative
        if CGDisplayIsBuiltin(displayID) == 1 {
            return _cdGet?(displayID)
        }
        // External: try DDC first, then CoreDisplay, then IODisplay
        if let v = DDCManager.getBrightness(for: displayID) { return v }
        if let v = _cdGet?(displayID), v > 0 { return v }
        if let v = ioDisplayBrightness(for: displayID) { return Double(v) }
        return nil
    }

    static func setBrightness(_ value: Double, for displayID: CGDirectDisplayID) {
        let clamped = max(0.01, min(1.0, value))
        if CGDisplayIsBuiltin(displayID) == 1 {
            _cdSet?(displayID, clamped)
            return
        }
        // External: try DDC first
        if DDCManager.setBrightness(clamped, for: displayID) { return }
        _cdSet?(displayID, clamped)
        setIODisplayBrightness(Float(clamped), for: displayID)
    }

    // MARK: - IODisplay fallback

    private static func ioDisplayBrightness(for displayID: CGDirectDisplayID) -> Float? {
        guard let svc = ioService(for: displayID) else { return nil }
        defer { IOObjectRelease(svc) }
        var value: Float = 0
        guard IODisplayGetFloatParameter(svc, 0, kIODisplayBrightnessKey as CFString, &value) == KERN_SUCCESS else { return nil }
        return value
    }

    private static func setIODisplayBrightness(_ value: Float, for displayID: CGDirectDisplayID) {
        guard let svc = ioService(for: displayID) else { return }
        defer { IOObjectRelease(svc) }
        IODisplaySetFloatParameter(svc, 0, kIODisplayBrightnessKey as CFString, value)
    }

    private static func ioService(for displayID: CGDirectDisplayID) -> io_service_t? {
        var iter: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IODisplayConnect"), &iter) == KERN_SUCCESS else { return nil }
        defer { IOObjectRelease(iter) }

        var svc = IOIteratorNext(iter)
        while svc != 0 {
            if let info = IODisplayCreateInfoDictionary(svc, IOOptionBits(kIODisplayOnlyPreferredName))?.takeRetainedValue() as? [String: AnyObject] {
                let vendor  = (info["DisplayVendorID"]  as? UInt32) ?? 0
                let product = (info["DisplayProductID"] as? UInt32) ?? 0
                if vendor == CGDisplayVendorNumber(displayID) && product == CGDisplayModelNumber(displayID) {
                    return svc
                }
            }
            IOObjectRelease(svc)
            svc = IOIteratorNext(iter)
        }
        return nil
    }
}
