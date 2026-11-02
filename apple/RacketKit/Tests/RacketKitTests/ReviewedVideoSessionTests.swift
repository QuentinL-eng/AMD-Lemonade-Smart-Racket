import XCTest
import simd
@testable import RacketKit

/// Optional replay against actual visually reviewed video contacts. The file paths
/// are supplied explicitly; local recordings are not bundled into the package.
/// This session contains only forehands and cannot validate the other shot types.
final class ReviewedVideoSessionTests: XCTestCase {
    func testReviewedForehandBaseline() throws {
        let env = ProcessInfo.processInfo.environment
        guard let rawPath = env["REVIEWED_SENSOR_CSV"], let eventPath = env["REVIEWED_SENSOR_EVENTS"] else {
            throw XCTSkip("Reviewed real-racket recording paths not set")
        }
        let scale = try XCTUnwrap(env["REVIEWED_GYRO_SCALE"].flatMap(Float.init))
        let cal = Calibration.default
        let samples = try String(contentsOfFile: rawPath, encoding: .utf8).split(separator: "\n").dropFirst().map { line -> IMUSample in
            let values = line.split(separator: ",")
            let time = try XCTUnwrap(Double(values[0]))
            let v = try values.dropFirst().map { try XCTUnwrap(Float($0)) }
            return cal.apply(IMUSample(time: time, accel: SIMD3(v[0], v[1], v[2]),
                                       gyro: SIMD3(v[3], v[4], v[5]) * scale,
                                       highG: SIMD3(v[6], v[7], v[8])))
        }
        var filter = MahonyFilter()
        var orientations: [simd_quatf] = []
        for (k, s) in samples.enumerated() {
            let dt = Float(k == 0 ? 0.001 : min(max(s.time - samples[k - 1].time, 0.0002), 0.02))
            filter.update(gyro: s.gyro, accel: s.accel, dt: dt)
            orientations.append(filter.q)
        }
        var profile = RacketProfile()
        profile.forehandBodySign = 1  // Taught on the separate room recording.
        let analyzer = ShotAnalyzer(profile: profile, model: ImpactModel())
        let events = try String(contentsOfFile: eventPath, encoding: .utf8).split(separator: "\n").dropFirst()
        XCTAssertEqual(events.count, 29)
        var correct = 0
        for event in events {
            let fields = event.split(separator: ",")
            let index = try XCTUnwrap(Int(fields[0]))
            XCTAssertEqual(fields[1], "forehand")
            let lo = max(0, index - 700), hi = min(samples.count, index + 150)
            let shot = analyzer.analyze(window: Array(samples[lo..<hi]), impact: index-lo,
                                        orientation: orientations[max(index-3, 0)], date: Date(), calibrationMode: false)
            if shot.type == .forehand { correct += 1 }
            print("Reviewed sample \(index): \(shot.type.rawValue)")
        }
        print("Reviewed forehand baseline: \(correct)/\(events.count); other classes untested")
        // Frozen measured baseline, not a general four-class performance claim.
        XCTAssertEqual(correct, 28)
    }
}
