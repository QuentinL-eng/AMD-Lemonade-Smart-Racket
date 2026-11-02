import Foundation

/// Firmware versions whose rotation scale was checked against the physical robot.
public enum MotionFirmware {
    public static let minimumCorrectedVersion = "1.8"

    /// These builds flagged 4000 dps while the IMU remained at 2000 dps, doubling
    /// both the recorded angular rates and the firmware's orientation integration.
    /// Halving a displayed speed cannot repair the already-integrated orientation.
    public static func hasKnownGyroScaleBug(_ version: String) -> Bool {
        let parts = version.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count >= 2, let major = Int(parts[0]), let minor = Int(parts[1]) else { return false }
        return major == 1 && (5...7).contains(minor)
    }
}
