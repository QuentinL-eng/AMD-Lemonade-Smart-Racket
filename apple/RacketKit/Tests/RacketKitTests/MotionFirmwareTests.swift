import XCTest
@testable import RacketKit

final class MotionFirmwareTests: XCTestCase {
    func testKnownAffectedBuildsAndCorrectedVersions() {
        for version in ["1.5", "1.6", "1.7", "1.6.1"] {
            XCTAssertTrue(MotionFirmware.hasKnownGyroScaleBug(version), version)
        }
        for version in ["1.4", "1.8", "1.9", "1.10", "2.0", "unknown", "", "1."] {
            XCTAssertFalse(MotionFirmware.hasKnownGyroScaleBug(version), version)
        }
    }
}
