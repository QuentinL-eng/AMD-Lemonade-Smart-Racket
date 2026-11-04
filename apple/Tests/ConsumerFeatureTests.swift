import Foundation
import RacketKit
import SwiftData
import XCTest

@MainActor
final class ConsumerFeatureTests: XCTestCase {
    func testSharedScoreUsesWearersPerspectiveThroughDeuceAndUndo() {
        let a = UUID(), b = UUID()
        var state = SharedMatchState(id: UUID(), title: "Singles",
            host: SocialProfile(id: a, name: "Alice", friendCode: ""),
            guest: SocialProfile(id: b, name: "Bob", friendCode: ""), inviteCode: "TEST",
            ended: false, revision: 6, points: [], stats: [])
        for winner in [a, b, a, b, a, b] { state.points.append(SharedPoint(id: UUID(), winner: winner)) }
        XCTAssertEqual(state.tracker(for: a).score.pointText, "Deuce")
        XCTAssertEqual(state.tracker(for: b).score.pointText, "Deuce")
        state.points.append(SharedPoint(id: UUID(), winner: a))
        XCTAssertEqual(state.tracker(for: a).score.pointText, "Ad you")
        XCTAssertEqual(state.tracker(for: b).score.pointText, "Ad opponent")
        state.points.append(SharedPoint(id: UUID(), winner: a))
        XCTAssertEqual(state.tracker(for: a).score.games.me, 1)
        XCTAssertEqual(state.tracker(for: b).score.games.opponent, 1)
        state.points.removeLast()
        XCTAssertEqual(state.tracker(for: a).score.pointText, "Ad you")
    }

    func testWorkoutOnlySessionSurvivesAndLateCaloriesUseExactRecord() throws {
        let schema = Schema([SessionRecord.self, ShotRecord.self])
        let container = try ModelContainer(for: schema,
            configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none))
        let app = AppModel()
        defer { app.simulator.stop() }
        app.modelContext = container.mainContext
        app.signedInPlayerName = "Alice"
        app.startSession()
        let first = try XCTUnwrap(app.activeSession)
        first.title = " Evening tennis "
        app.stopSession()
        app.startSession()
        let second = try XCTUnwrap(app.activeSession)
        app.recordHealth(averageHeartRate: 0, calories: 210, sessionID: first.id)
        app.recordHealth(averageHeartRate: 0, calories: 200, sessionID: first.id)
        XCTAssertEqual(first.activeCalories, 210) // A delayed earlier snapshot cannot reduce the total.
        XCTAssertEqual(second.activeCalories, 0)
        XCTAssertEqual(first.title, "Evening tennis")
        XCTAssertEqual(first.playerName, "Alice")
        XCTAssertNotNil(first.endDate)
        XCTAssertEqual(try container.mainContext.fetchCount(FetchDescriptor<SessionRecord>()), 2)
        app.recordHealth(averageHeartRate: .nan, calories: .infinity, sessionID: first.id)
        XCTAssertEqual(first.activeCalories, 210)
        XCTAssertEqual(first.averageHeartRate, 0)
    }

    func testSharedRecordingStoresMembershipAndRequiresNoRacket() throws {
        let app = AppModel()
        defer { app.simulator.stop() }
        let match = UUID(), player = UUID()
        app.startSharedRecording(matchID: match, playerID: player)
        XCTAssertEqual(app.activeSession?.sharedMatchID, match.uuidString)
        XCTAssertEqual(app.activeSession?.sharedPlayerID, player.uuidString)
        app.logPoint(won: true)
        XCTAssertEqual(app.activeSession?.pointsWon, 1)
        app.stopSession()
        XCTAssertFalse(app.isSessionActive)
    }
}

final class AppleSignInChallengeTests: XCTestCase {
    func testSHA256NonceUsesExpectedEncoding() {
        XCTAssertEqual(AppleSignInChallenge.hash("abc"),
            "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }

    func testEachRequestHasIndependentSecureNonceAndState() throws {
        let first = try AppleSignInChallenge()
        let second = try AppleSignInChallenge()
        XCTAssertEqual(first.nonce.count, 64)
        XCTAssertEqual(first.state.count, 64)
        XCTAssertNotEqual(first.nonce, first.state)
        XCTAssertNotEqual(first.nonce, second.nonce)
        XCTAssertNotEqual(first.state, second.state)
        XCTAssertNotEqual(first.nonce, first.hashedNonce)
        XCTAssertNoThrow(try first.validate(returnedState: first.state))
        XCTAssertThrowsError(try first.validate(returnedState: second.state))
        XCTAssertThrowsError(try first.validate(returnedState: nil))
    }
}

@MainActor
final class WhatIfTrialTests: XCTestCase {
    func testTrialRoundTripsFromSuggestionToFollowUp() throws {
        let schema = Schema([WhatIfTrial.self])
        let container = try ModelContainer(for: schema,
            configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none))
        let context = container.mainContext
        let trial = WhatIfTrial(sessionID: UUID(), stroke: "forehand", goal: "more spin",
            deltas: WhatIf.Deltas(pathDeg: 8), predicted: (110, 110, 1058, 1554),
            measuredBefore: (106, 1049))
        context.insert(trial)
        try context.save()
        XCTAssertFalse(trial.isComplete)
        XCTAssertEqual(try context.fetch(FetchDescriptor<WhatIfTrial>(
            predicate: #Predicate { $0.completedAt == nil })).count, 1)
        trial.complete(followUpSessionID: UUID(), measuredBall: 108, measuredSpin: 1420)
        try context.save()
        XCTAssertTrue(trial.isComplete)
        XCTAssertEqual(trial.deltas.pathDeg, 8)
        XCTAssertEqual(try context.fetch(FetchDescriptor<WhatIfTrial>(
            predicate: #Predicate { $0.completedAt != nil })).count, 1)
    }
}
