import AppKit
import CoreGraphics

struct DisplayInfo {
    let id: CGDirectDisplayID
    let name: String
    let logicalWidth: Int
    let logicalHeight: Int
    let nativeWidth: Int
    let nativeHeight: Int
    let isMain: Bool
    let refreshRate: Double
    let scaleFactor: CGFloat
}

enum DisplayManager {
    static func activeDisplays() -> [DisplayInfo] {
        NSScreen.screens.compactMap { screen in
            guard let id = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else {
                return nil
            }
            let refreshRate = CGDisplayCopyDisplayMode(id)?.refreshRate ?? 0
            let scale = screen.backingScaleFactor
            return DisplayInfo(
                id: id,
                name: screen.localizedName,
                logicalWidth: Int(screen.frame.width),
                logicalHeight: Int(screen.frame.height),
                nativeWidth: Int(screen.frame.width * scale),
                nativeHeight: Int(screen.frame.height * scale),
                isMain: screen == NSScreen.main,
                refreshRate: refreshRate,
                scaleFactor: scale
            )
        }
    }
}
