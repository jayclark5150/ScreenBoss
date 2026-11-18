import Darwin
import CoreGraphics

enum TrueToneManager {
    private static let lib = dlopen(
        "/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_LAZY)

    private static let _hasSupport: (@convention(c) (CGDirectDisplayID) -> Bool)? = sym("DisplayServicesHasAmbientColorSupport")
    private static let _getEnabled: (@convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Bool>) -> Int32)? = sym("DisplayServicesGetAmbientColorEnabled")
    private static let _setEnabled: (@convention(c) (CGDirectDisplayID, Bool) -> Int32)? = sym("DisplayServicesSetAmbientColorEnabled")

    private static func sym<T>(_ name: String) -> T? {
        guard let lib, let raw = dlsym(lib, name) else { return nil }
        return unsafeBitCast(raw, to: T.self)
    }

    static func isSupported(for displayID: CGDirectDisplayID) -> Bool {
        _hasSupport?(displayID) ?? false
    }

    static func isEnabled(for displayID: CGDirectDisplayID) -> Bool {
        var value = false
        _getEnabled?(displayID, &value)
        return value
    }

    static func setEnabled(_ enabled: Bool, for displayID: CGDirectDisplayID) {
        _setEnabled?(displayID, enabled)
    }
}
