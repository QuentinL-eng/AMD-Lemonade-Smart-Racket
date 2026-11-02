import XCTest
@testable import RacketKit

/// The racket checks the same CRC-32 (firmware/src/ota.cpp), and the app only offers newer firmware.
final class FirmwareImageTests: XCTestCase {
    func testCRC32MatchesStandardCheckValue() {
        XCTAssertEqual(FirmwareImage(data: Data("123456789".utf8), version: nil).crc32, 0xCBF4_3926)
    }

    func testVersionComparison() {
        let image = FirmwareImage(data: Data(), version: "1.10")
        XCTAssertTrue(image.isNewer(than: "1.9"))
        XCTAssertTrue(image.isNewer(than: "1.2"))
        XCTAssertFalse(image.isNewer(than: "1.10"))
        XCTAssertFalse(image.isNewer(than: "2.0"))
        XCTAssertFalse(FirmwareImage(data: Data(), version: nil).isNewer(than: "1.0"))
    }

    func testBundledFirmwareMatchesSourceVersionAndImageHash() throws {
        let repo = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let resources = repo.appendingPathComponent("apple/Shared/Resources")
        let image = try Data(contentsOf: resources.appendingPathComponent("RacketFirmware.bin"))
        let metadata = try JSONDecoder().decode([String: String].self,
                       from: Data(contentsOf: resources.appendingPathComponent("RacketFirmware.json")))
        let header = try String(contentsOf: repo.appendingPathComponent("firmware/include/protocol.h"), encoding: .utf8)
        func value(_ name: String) throws -> String {
            let line = try XCTUnwrap(header.split(separator: "\n").first { $0.hasPrefix("#define \(name) ") })
            return try XCTUnwrap(line.split(whereSeparator: \.isWhitespace).last).description
        }
        let version = try "\(value("TB_FW_MAJOR")).\(value("TB_FW_MINOR"))"
        XCTAssertEqual(metadata["version"], version, "Rebuild the app's firmware bundle after changing firmware")
        XCTAssertEqual(metadata["sha256"], FirmwareImage.sha256(image))
        XCTAssertTrue(FirmwareImage(data: image, version: version).looksValid)
        XCTAssertFalse(MotionFirmware.hasKnownGyroScaleBug(try XCTUnwrap(metadata["version"])))
    }
}
