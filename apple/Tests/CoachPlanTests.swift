import XCTest
import RacketKit

@MainActor
final class CoachPlanTests: XCTestCase {
    func shot(date: Date, speed: Double = 90, type: ShotType = .forehand, x: Double = 1, y: Double = 2) -> ShotMetrics {
        ShotMetrics(date: date, type: type, swingSpeedKmh: speed, ballSpeedKmh: speed * 1.4,
            spinRPM: 1600, spin: .topspin, faceAngleDeg: 0, swingPathDeg: 20,
            impactXcm: x, impactYcm: y, peakG: 100, gyroSaturated: false,
            features: ImpactFeatures(rollRatio: 0, ringNorm: 0, jolt: 0, impulse: 5))
    }

    func session(speeds: [Double] = [100, 100, 100, 100], weakBackhand: Bool = false) -> SessionRecord {
        let s = SessionRecord(startDate: Date(timeIntervalSince1970: 1000))
        s.endDate = s.startDate.addingTimeInterval(60)
        var recs = speeds.enumerated().map { i, v in
            ShotRecord(metrics: shot(date: s.startDate.addingTimeInterval(Double(i)), speed: v))
        }
        if weakBackhand {
            recs += [ShotRecord(metrics: shot(date: s.startDate, speed: 90, type: .backhand, x: 8, y: 8)),
                     ShotRecord(metrics: shot(date: s.startDate, speed: 90, type: .backhand, x: 8, y: 8))]
        }
        s.shotRecords = recs
        return s
    }

    func opponent() -> ScoutOpponent {
        ScoutOpponent(name: "Rival", shots: 50, sweetPercent: 70, avgBall: 120, topBall: 150, speedUnit: "km/h")
    }

    func testScoutPromptCarriesOpponentBlock() {
        let d = SessionDigest(session: session())
        let p = CoachPrompts.scout(d, opponent: opponent())
        XCTAssertTrue(p.contains("Rival: 50 shots, 70% sweet spot"))
        XCTAssertTrue(p.contains("match plan"))
        XCTAssertTrue(p.contains("shared totals, not your measurements"))
    }

    func testSelfScoutPromptUsesCompareTools() {
        let d = SessionDigest(session: session())
        let p = CoachPrompts.scout(d, opponent: nil)
        XCTAssertTrue(p.contains("compare_sessions"))
        XCTAssertFalse(p.contains("shared totals (given"))
    }

    func testTemplateScoutComparesSweetSpot() async throws {
        let d = SessionDigest(session: session())
        let text = try await TemplateCoach().scout(d, opponent: opponent())
        XCTAssertTrue(text.contains("Rival"))
        XCTAssertTrue(text.contains("shared totals"))
    }

    func testTemplateScoutSelfScoutWithoutOpponent() async throws {
        let d = SessionDigest(session: session(), weakBackhand: true)
        let text = try await TemplateCoach().scout(d, opponent: nil)
        XCTAssertTrue(text.contains("backhand"))
    }

    func testPracticePlanParsesThreeSteps() async throws {
        let d = SessionDigest(session: session(), weakBackhand: true)
        let text = try await TemplateCoach().plan(d)
        let plan = PracticePlan.parse(text, sessionID: UUID())
        XCTAssertEqual(plan.steps.count, 3)
        XCTAssertEqual(plan.steps.map(\.drill.target), [10, 8, 20])
        XCTAssertEqual(plan.steps[2].drill.criterion, .any)
        XCTAssertFalse(plan.steps[0].note.isEmpty)
    }

    func testPracticePlanToleratesGarbage() {
        let plan = PracticePlan.parse("just some words", sessionID: UUID())
        XCTAssertEqual(plan.steps.count, 1)
        XCTAssertEqual(plan.title, "Next practice")
    }

    func testPracticePlanPromptFormat() {
        let d = SessionDigest(session: session())
        let p = CoachPrompts.plan(d)
        XCTAssertTrue(p.contains("STEP 1:") && p.contains("STEP 3:"))
        XCTAssertTrue(p.contains("NOTE:"))
    }

    func testReviewFlagsParse() {
        let (flags, clear) = ReviewFlag.parseAll(
            "FLAG: Late fade\nDETAIL: Speed dropped 150 to 138 km/h.\nEVIDENCE: thirds 150->138 km/h\n" +
            "FLAG: Backhand contact\nDETAIL: Only 30% sweet.\nEVIDENCE: backhand 30% sweet")
        XCTAssertNil(clear)
        XCTAssertEqual(flags.count, 2)
        XCTAssertEqual(flags[0].label, "Late fade")
        XCTAssertTrue(flags[0].evidence.contains("138"))
    }

    func testReviewClearParses() {
        let (flags, clear) = ReviewFlag.parseAll("CLEAR: Steady session.")
        XCTAssertTrue(flags.isEmpty)
        XCTAssertEqual(clear, "Steady session.")
    }

    func testTemplateReviewFlagsFatigue() async throws {
        let d = SessionDigest(session: session(speeds: [120, 120, 100, 100, 60, 60]))
        let text = try await TemplateCoach().review(d)
        XCTAssertTrue(text.contains("FLAG: Late fade"))
        let (flags, _) = ReviewFlag.parseAll(text)
        XCTAssertEqual(flags.count, 1)
    }

    func testTemplateReviewClearWhenSteady() async throws {
        let d = SessionDigest(session: session())
        let text = try await TemplateCoach().review(d)
        XCTAssertTrue(text.hasPrefix("CLEAR:"))
    }

    func testCoachReviewDecide() {
        let r = CoachReview(sessionID: UUID(), flags: [ReviewFlag(label: "X", detail: "Y", evidence: "Z")])
        XCTAssertEqual(r.status, .pending)
        XCTAssertEqual(r.flags.count, 1)
        XCTAssertFalse(r.isClear)
        r.decide(.approved)
        XCTAssertEqual(r.status, .approved)
        XCTAssertNotNil(r.reviewedAt)
    }
}
