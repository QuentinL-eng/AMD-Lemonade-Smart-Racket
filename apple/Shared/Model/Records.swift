import Foundation
import RacketKit
import SwiftData

/// A practice session. All properties have defaults so the store can sync with CloudKit later.
@Model
final class SessionRecord {
    var id: UUID = UUID()
    var startDate: Date = Date()
    var endDate: Date?
    var title: String = ""
    /// Name of the player who was active when the session started.
    var playerName: String = ""
    var sharedMatchID: String = ""
    var sharedPlayerID: String = ""
    var sharedStatsPending: Bool = false
    var notes: String = ""
    var coachSummary: String = ""
    var pointsWon: Int = 0
    var pointsLost: Int = 0
    var averageHeartRate: Double = 0
    var activeCalories: Double = 0
    @Relationship(deleteRule: .cascade, inverse: \ShotRecord.session) var shotRecords: [ShotRecord]? = []

    init(startDate: Date = Date()) {
        self.startDate = startDate
        self.title = startDate.formatted(.dateTime.weekday(.wide).hour().minute())
    }

    var shots: [ShotMetrics] {
        (shotRecords ?? []).compactMap(\.metrics).sorted { $0.date < $1.date }
    }

    var duration: TimeInterval { (endDate ?? Date()).timeIntervalSince(startDate) }
    var summary: ShotSummary { ShotSummary(shots.filter { $0.type != .calibration }) }
}

@Model
final class ShotRecord {
    var date: Date = Date()
    var typeRaw: String = ShotType.forehand.rawValue
    var metricsData: Data = Data()
    var bookmarked: Bool = false
    var dataSourceRaw: String = ""
    var session: SessionRecord?

    init(metrics: ShotMetrics) {
        date = metrics.date
        typeRaw = metrics.type.rawValue
        metricsData = (try? JSONEncoder().encode(metrics)) ?? Data()
    }

    var metrics: ShotMetrics? { try? JSONDecoder().decode(ShotMetrics.self, from: metricsData) }
}

/// Something the coach should remember about a player across sessions ("rushes the backhand when tired",
/// "sore right elbow in 2025"). Written by the player, or by Racket agent through `remember_note`.
@Model
final class CoachNote {
    var id: UUID = UUID()
    /// `PlayerProfile.id` of the player the note is about.
    var playerID: UUID = UUID()
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var text: String = ""
    var categoryRaw: String = CoachNote.Category.technique.rawValue
    /// "player" or "coach".
    var source: String = "player"
    /// The session that prompted the note, when there was one.
    var sessionID: UUID?

    enum Category: String, CaseIterable, Identifiable, Codable {
        case technique, fitness, injury, goal, preference, other
        var id: String { rawValue }
        var label: String { rawValue.capitalized }
        var symbol: String {
            switch self {
            case .technique: "figure.tennis"
            case .fitness: "bolt.heart"
            case .injury: "bandage"
            case .goal: "flag"
            case .preference: "slider.horizontal.3"
            case .other: "note.text"
            }
        }
    }

    init(playerID: UUID, text: String, category: Category, source: String = "player", sessionID: UUID? = nil) {
        self.playerID = playerID
        self.text = text
        self.categoryRaw = category.rawValue
        self.source = source
        self.sessionID = sessionID
    }

    var category: Category {
        get { Category(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
    var addedByCoach: Bool { source == "coach" }
}

/// One flagged moment from a session review: what needs a human's eyes and the numbers behind it.
struct ReviewFlag: Codable, Sendable, Equatable, Identifiable {
    var id = UUID()
    var label: String
    var detail: String
    var evidence: String

    /// Parses the review reply ("FLAG: …\nDETAIL: …\nEVIDENCE: …" blocks, or "CLEAR: …").
    /// Returns the flags plus the all-clear note when there is nothing to review.
    static func parseAll(_ text: String) -> (flags: [ReviewFlag], clear: String?) {
        func field(_ block: String, _ name: String) -> String {
            for line in block.components(separatedBy: .newlines) {
                let trimmed = line.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "*", with: "")
                if trimmed.uppercased().hasPrefix(name + ":") {
                    return String(trimmed.dropFirst(name.count + 1)).trimmingCharacters(in: .whitespaces)
                }
            }
            return ""
        }
        if let clearLine = text.components(separatedBy: .newlines).first(where: {
            $0.trimmingCharacters(in: .whitespaces).uppercased().hasPrefix("CLEAR:")
        }) {
            let note = clearLine.trimmingCharacters(in: .whitespaces).dropFirst("CLEAR:".count)
                .trimmingCharacters(in: .whitespaces)
            return ([], note.isEmpty ? "Nothing needs a review." : note)
        }
        var flags: [ReviewFlag] = []
        for block in text.components(separatedBy: "FLAG:").dropFirst().prefix(4) {
            let label = field("FLAG: " + block, "FLAG")
            let detail = field(block, "DETAIL")
            guard !label.isEmpty else { continue }
            flags.append(ReviewFlag(label: label, detail: detail, evidence: field(block, "EVIDENCE")))
        }
        return (flags, nil)
    }
}

/// A session review: Racket agent (or the built-in engine) flags what needs a human coach's eyes,
/// and the coach approves or dismisses each review. Single-coach, single-player flow.
@Model
final class CoachReview {
    var id: UUID = UUID()
    var sessionID: UUID = UUID()
    var createdAt: Date = Date()
    var statusRaw: String = Status.pending.rawValue
    var reviewedAt: Date?
    var flagsData: Data = Data()
    var clearNote: String = ""
    /// Which engine wrote it, so the UI can name it like every other answer.
    var engineName: String = ""

    enum Status: String, Codable, CaseIterable {
        case pending, approved, dismissed
    }

    init(sessionID: UUID, flags: [ReviewFlag] = [], clearNote: String = "", engineName: String = "") {
        self.sessionID = sessionID
        self.flagsData = (try? JSONEncoder().encode(flags)) ?? Data()
        self.clearNote = clearNote
        self.engineName = engineName
    }

    var status: Status {
        get { Status(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }

    var flags: [ReviewFlag] { (try? JSONDecoder().decode([ReviewFlag].self, from: flagsData)) ?? [] }
    var isClear: Bool { flags.isEmpty }

    func decide(_ status: Status, at date: Date = Date()) {
        self.status = status
        reviewedAt = date
    }
}

/// A what-if suggestion the player decided to try: the simulator's estimated before/after plus the measured
/// before/after once they have played again. Completed trials are the outcome labels the estimates are checked
/// against.
@Model
final class WhatIfTrial {
    var id: UUID = UUID()
    var createdAt: Date = Date()
    /// The session the suggestion was made on.
    var sessionID: UUID = UUID()
    /// Stroke the change applies to ("forehand", "backhand", "serve", "volley", "" for every stroke).
    var stroke: String = ""
    /// The goal in plain words ("more spin", "cleaner contact", ...).
    var goal: String = ""
    var swingPercent = 0.0
    var faceDeg = 0.0
    var pathDeg = 0.0
    var contactXcm = 0.0
    var contactYcm = 0.0
    /// The simulator's estimate, in km/h and rpm.
    var predictedBallBefore = 0.0
    var predictedBallAfter = 0.0
    var predictedSpinBefore = 0.0
    var predictedSpinAfter = 0.0
    /// The measured session averages when the trial started, in km/h and rpm.
    var measuredBallBefore = 0.0
    var measuredSpinBefore = 0.0
    /// The session the follow-up was measured on, once played.
    var followUpSessionID: UUID?
    var measuredBallAfter = 0.0
    var measuredSpinAfter = 0.0
    var completedAt: Date?

    init(sessionID: UUID, stroke: String = "", goal: String = "", deltas: WhatIf.Deltas = WhatIf.Deltas(),
         predicted: (ballBefore: Double, ballAfter: Double, spinBefore: Double, spinAfter: Double) = (0, 0, 0, 0),
         measuredBefore: (ball: Double, spin: Double) = (0, 0)) {
        self.sessionID = sessionID
        self.stroke = stroke
        self.goal = goal
        swingPercent = deltas.swingPercent
        faceDeg = deltas.faceDeg
        pathDeg = deltas.pathDeg
        contactXcm = deltas.contactXcm
        contactYcm = deltas.contactYcm
        predictedBallBefore = predicted.ballBefore
        predictedBallAfter = predicted.ballAfter
        predictedSpinBefore = predicted.spinBefore
        predictedSpinAfter = predicted.spinAfter
        measuredBallBefore = measuredBefore.ball
        measuredSpinBefore = measuredBefore.spin
    }

    var deltas: WhatIf.Deltas {
        WhatIf.Deltas(swingPercent: swingPercent, faceDeg: faceDeg, pathDeg: pathDeg,
                      contactXcm: contactXcm, contactYcm: contactYcm)
    }

    var isComplete: Bool { completedAt != nil }

    /// Record the follow-up once the player has played again.
    func complete(followUpSessionID: UUID, measuredBall: Double, measuredSpin: Double, at date: Date = Date()) {
        self.followUpSessionID = followUpSessionID
        measuredBallAfter = measuredBall
        measuredSpinAfter = measuredSpin
        completedAt = date
    }
}
