import IOKit
import CoreGraphics

/// DDC/CI brightness control for external monitors via IOKit I2C.
enum DDCManager {

    static let VCP_BRIGHTNESS: UInt8 = 0x10

    struct VCPReply {
        let current: UInt16
        let max: UInt16
    }

    // MARK: - Public API

    static func getBrightness(for displayID: CGDirectDisplayID) -> Double? {
        guard let r = readVCP(displayID: displayID, vcp: VCP_BRIGHTNESS), r.max > 0 else { return nil }
        return Double(r.current) / Double(r.max)
    }

    @discardableResult
    static func setBrightness(_ value: Double, for displayID: CGDirectDisplayID) -> Bool {
        guard let r = readVCP(displayID: displayID, vcp: VCP_BRIGHTNESS), r.max > 0 else { return false }
        let newVal = UInt16(round(max(0, min(1, value)) * Double(r.max)))
        return writeVCP(displayID: displayID, vcp: VCP_BRIGHTNESS, value: newVal)
    }

    // MARK: - VCP read / write

    static func readVCP(displayID: CGDirectDisplayID, vcp: UInt8) -> VCPReply? {
        guard let connect = openI2C(for: displayID) else { return nil }
        defer { IOI2CInterfaceClose(connect, 0) }

        let chk = UInt8(0x82 ^ 0x01 ^ vcp)
        var result: VCPReply?

        withUnsafeTemporaryAllocation(byteCount: 4, alignment: 1) { sBuf in
            sBuf[0] = 0x82; sBuf[1] = 0x01; sBuf[2] = vcp; sBuf[3] = chk
            withUnsafeTemporaryAllocation(byteCount: 11, alignment: 1) { rBuf in
                for i in 0..<11 { rBuf[i] = 0 }
                var req = IOI2CRequest()
                req.commFlags            = 0
                req.sendAddress          = 0x6E
                req.sendSubAddress       = 0
                req.sendTransactionType  = IOOptionBits(kIOI2CSimpleTransactionType)
                req.sendBuffer           = UInt(bitPattern: sBuf.baseAddress!)
                req.sendBytes            = 4
                req.replyAddress         = 0x6F
                req.replySubAddress      = 0
                req.replyTransactionType = IOOptionBits(kIOI2CSimpleTransactionType)
                req.replyBuffer          = UInt(bitPattern: rBuf.baseAddress!)
                req.replyBytes           = 11
                req.minReplyDelay        = 10_000

                if IOI2CSendRequest(connect, IOOptionBits(kIOI2CUseSubAddressCommFlag), &req) == KERN_SUCCESS,
                   req.result == KERN_SUCCESS,
                   rBuf[2] == 0x02 {
                    let maxVal = (UInt16(rBuf[6]) << 8) | UInt16(rBuf[7])
                    let curVal = (UInt16(rBuf[8]) << 8) | UInt16(rBuf[9])
                    result = VCPReply(current: curVal, max: maxVal)
                }
            }
        }
        return result
    }

    @discardableResult
    static func writeVCP(displayID: CGDirectDisplayID, vcp: UInt8, value: UInt16) -> Bool {
        guard let connect = openI2C(for: displayID) else { return false }
        defer { IOI2CInterfaceClose(connect, 0) }

        let hi  = UInt8((value >> 8) & 0xFF)
        let lo  = UInt8(value & 0xFF)
        let chk = UInt8(0x6E ^ 0x84 ^ 0x03 ^ vcp ^ hi ^ lo)
        var ok  = false

        withUnsafeTemporaryAllocation(byteCount: 6, alignment: 1) { sBuf in
            sBuf[0] = 0x84; sBuf[1] = 0x03; sBuf[2] = vcp
            sBuf[3] = hi;   sBuf[4] = lo;   sBuf[5] = chk
            var req = IOI2CRequest()
            req.commFlags            = 0
            req.sendAddress          = 0x6E
            req.sendSubAddress       = 0
            req.sendTransactionType  = IOOptionBits(kIOI2CSimpleTransactionType)
            req.sendBuffer           = UInt(bitPattern: sBuf.baseAddress!)
            req.sendBytes            = 6
            req.replyBytes           = 0
            req.replyTransactionType = IOOptionBits(kIOI2CNoTransactionType)
            ok = IOI2CSendRequest(connect, IOOptionBits(kIOI2CUseSubAddressCommFlag), &req) == KERN_SUCCESS
        }
        return ok
    }

    // MARK: - IOKit helpers

    private static func openI2C(for displayID: CGDirectDisplayID) -> IOI2CConnectRef? {
        guard let fb = framebuffer(for: displayID) else { return nil }
        defer { IOObjectRelease(fb) }

        var busCount: IOItemCount = 0
        guard IOFBGetI2CInterfaceCount(fb, &busCount) == KERN_SUCCESS, busCount > 0 else { return nil }

        var busInterface: io_service_t = 0
        guard IOFBCopyI2CInterfaceForBus(fb, 0, &busInterface) == KERN_SUCCESS else { return nil }
        defer { IOObjectRelease(busInterface) }

        var connect: IOI2CConnectRef?
        guard IOI2CInterfaceOpen(busInterface, 0, &connect) == KERN_SUCCESS else { return nil }
        return connect
    }

    private static func framebuffer(for displayID: CGDirectDisplayID) -> io_service_t? {
        let unit = CGDisplayUnitNumber(displayID)
        var iter: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOFramebuffer"), &iter) == KERN_SUCCESS else { return nil }
        defer { IOObjectRelease(iter) }

        var svc = IOIteratorNext(iter)
        while svc != 0 {
            if let idx = IORegistryEntryCreateCFProperty(svc, "IOFramebufferOpenGLIndex" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? UInt32,
               idx == unit {
                return svc  // caller must release
            }
            IOObjectRelease(svc)
            svc = IOIteratorNext(iter)
        }
        return nil
    }
}
