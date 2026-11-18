import Foundation

enum NightShiftManager {
    private static let client: CBBlueLightClient? = CBBlueLightClient()

    static var isEnabled: Bool {
        var s = CBBlueLightStatusData()
        client?.getBlueLightStatus(&s)
        return s.enabled
    }

    static func setEnabled(_ enabled: Bool) {
        client?.setEnabled(enabled)
    }

    static var strength: Float {
        var s = CBBlueLightStatusData()
        client?.getBlueLightStatus(&s)
        return s.strength
    }

    static func setStrength(_ value: Float) {
        client?.setStrength(value, commit: true)
    }
}
