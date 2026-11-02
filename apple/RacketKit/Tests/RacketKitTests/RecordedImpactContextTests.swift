import XCTest
import simd
@testable import RacketKit

final class RecordedImpactContextTests: XCTestCase {
    private func fixture() -> ImpactWindow {
        let samples = (0..<448).map { k in
            IMUSample(time: 10 + Double(k) * 0.001, accel: SIMD3(0.3, 0.4, 0.8),
                      gyro: SIMD3(4, 11, -3), highG: SIMD3(0, 0, k == 384 ? 25 : 1))
        }
        return ImpactWindow(seq: 19, impactIndex: 384,
                            startOrientation: simd_quatf(angle: 1.1, axis: simd_normalize(SIMD3(1, 2, 3))),
                            samples: samples, boot: 7)
    }

    func testSavedPoseAndConfigurationReproduceWindowAnalysis() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let recorder = Recorder()
        try recorder.start(in: folder, name: "fixture")
        let prefix = [IMUSample(time: 1, accel: .zero, gyro: .zero, highG: .zero)]
        recorder.append(RecordingEvent.samples(prefix))
        let window = fixture()
        var cal = Calibration.default
        cal.gyroBias = SIMD3(0.01, 0.02, -0.01)
        var profile = RacketProfile()
        profile.rightHanded = false
        profile.forehandBodySign = -1
        let model = ImpactModel()
        recorder.append(RecordingEvent.impact(window: window, calibration: cal, profile: profile, model: model))
        let url = try XCTUnwrap(recorder.stop())
        let samples = RecordingFormat.decode(try Data(contentsOf: url))
        XCTAssertEqual(samples.count, 449)
        XCTAssertEqual(recorder.missingImpactContexts, 0)
        let lines = try String(contentsOf: url.deletingPathExtension().appendingPathExtension("windows.jsonl"),
                               encoding: .utf8).split(separator: "\n")
        XCTAssertEqual(lines.count, 1)
        let context = try JSONDecoder().decode(RecordedImpactContext.self, from: Data(lines[0].utf8))
        XCTAssertEqual(context.sampleOffset, 1)
        XCTAssertEqual(context.calibration, cal)
        XCTAssertEqual(context.profile, profile)
        XCTAssertFalse(context.calibrationMode)
        let restored = try context.window(from: samples)
        XCTAssertEqual(restored.samples, window.samples)
        XCTAssertEqual(restored.seq, window.seq)
        XCTAssertEqual(restored.boot, window.boot)
        let date = Date(timeIntervalSince1970: 1)
        let expected = try XCTUnwrap(RacketEngine.shot(window: window, calibration: cal,
                    analyzer: ShotAnalyzer(profile: profile, model: model), calibrationMode: false, date: date))
        var actual = try XCTUnwrap(RacketEngine.shot(window: restored, calibration: context.calibration,
                    analyzer: ShotAnalyzer(profile: context.profile, model: context.model), calibrationMode: context.calibrationMode, date: date))
        actual.id = expected.id
        XCTAssertEqual(actual, expected)
    }

    func testCorruptOffsetsAndQuaternionsAreRejected() throws {
        let w = fixture()
        let valid = RecordedImpactContext(window: w, sampleOffset: 0, calibration: .default,
                                          profile: RacketProfile(), model: ImpactModel())
        var invalid = valid
        invalid.sampleOffset = Int.max
        XCTAssertThrowsError(try invalid.window(from: w.samples))
        invalid = valid; invalid.startOrientationXYZW = [0, 0, 0, 0]
        XCTAssertThrowsError(try invalid.window(from: w.samples))
        invalid = valid; invalid.sampleCount += 1
        XCTAssertThrowsError(try invalid.window(from: w.samples))
        invalid = valid; invalid.impactIndex = -1
        XCTAssertThrowsError(try invalid.window(from: w.samples))
    }
}
