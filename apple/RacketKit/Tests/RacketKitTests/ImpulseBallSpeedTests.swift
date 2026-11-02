import XCTest
import simd
@testable import RacketKit

final class ImpulseBallSpeedTests: XCTestCase {
    /// 100 samples, impact at 50: |ω| across the shaft 10 rad/s before, 5 rad/s after.
    private func window(post: SIMD3<Float> = SIMD3(0, 3, 4), count: Int = 100) -> [IMUSample] {
        (0..<count).map { k in
            IMUSample(time: Double(k) * 0.001, accel: SIMD3(0, 0, 1),
                      gyro: k < 50 ? SIMD3(0, 6, 8) : post, highG: k == 50 ? SIMD3(0, 0, 20) : .zero)
        }
    }

    private func run(_ w: [IMUSample], on: Bool) -> ShotMetrics {
        var model = ImpactModel()
        model.useImpulseBallSpeed = on
        return ShotAnalyzer(profile: RacketProfile(), model: model)
            .analyze(window: w, impact: 50, orientation: simd_quatf(angle: 0, axis: SIMD3(0, 0, 1)),
                     date: Date(timeIntervalSince1970: 0), calibrationMode: false)
    }

    private func oldBallMs(_ m: ShotMetrics) -> Float {
        let x = Float(m.impactXcm), y = Float(m.impactYcm)
        let e = ImpactModel().acorCenter * max(0.55, 1 - 0.035 * (x * x + y * y).squareRoot())
        return (1 + e) * 10 * RacketProfile().effectiveRadiusM
    }

    func testFlagOffKeepsOldFormulaAndRecordsBoth() {
        let m = run(window(), on: false)
        XCTAssertEqual(Float(m.ballSpeedKmh / 3.6), oldBallMs(m), accuracy: 1e-3)
        let r = RacketProfile().effectiveRadiusM
        XCTAssertEqual(m.features.racketDropMs!, r * 5, accuracy: 1e-4)
        XCTAssertEqual(m.features.ballSpeedImpulseMs!, r * (10 + 1.3 * 5), accuracy: 1e-3)
    }

    func testFlagOnUsesImpulse() {
        let m = run(window(), on: true)
        let r = RacketProfile().effectiveRadiusM
        XCTAssertEqual(Float(m.ballSpeedKmh / 3.6), r * (10 + 1.3 * 5), accuracy: 1e-3)
    }

    func testNoDropFallsBack() {
        let m = run(window(post: SIMD3(0, 6, 8)), on: true)
        XCTAssertNil(m.features.ballSpeedImpulseMs)
        XCTAssertEqual(Float(m.ballSpeedKmh / 3.6), oldBallMs(m), accuracy: 1e-3)
    }

    func testEmptyPostWindowFallsBack() {
        let m = run(window(count: 60), on: true)   // post window 62..<80 is past the end
        XCTAssertNil(m.features.ballSpeedImpulseMs)
        XCTAssertNil(m.features.racketDropMs)
        XCTAssertEqual(Float(m.ballSpeedKmh / 3.6), oldBallMs(m), accuracy: 1e-3)
    }

    func testClampsGainAndSpeed() {
        let s = ShotAnalyzer.impulseBallSpeed(wPre: SIMD3(0, 100, 0), wPost: .zero, postSamples: 18, radius: 1, gain: 9)
        XCTAssertEqual(s.speed, 90)
    }

    func testOldSavedModelDecodes() throws {
        let json = #"{"lateralGain":2,"longitudinalGain":10,"joltDeadband":0.02,"acorCenter":0.4,"spinGain":0.7}"#
        let m = try JSONDecoder().decode(ImpactModel.self, from: Data(json.utf8))
        XCTAssertEqual(m.lateralGain, 2)
        XCTAssertFalse(m.useImpulseBallSpeed)
        XCTAssertEqual(m.impulseGain, 1.3)
    }
}
