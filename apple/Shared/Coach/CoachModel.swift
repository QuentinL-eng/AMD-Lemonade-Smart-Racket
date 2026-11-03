import Foundation
import Observation
import RacketKit
import SwiftData

/// Builds the facts the coach talks about. Shared by the template coach and Muse.
struct SessionDigest: Codable {
    struct Stroke: Codable {
        var type: String
        var count: Int
        var sweetSpotPercent: Int
        var avgBallSpeed: Int
        var maxBallSpeed: Int
        var avgSwingSpeed: Int
        var avgSpinRPM: Int
        var avgPathDeg: Int
        var avgFaceDeg: Int
        var avgContactTowardTip: Double
        var avgContactRight: Double
        var contactSpread: Double
    }

    var speedUnit: String
    var lengthUnit: String
    var durationMinutes: Int
    var totalShots: Int
    var sweetSpotPercent: Int
    var pointsWon: Int
    var pointsLost: Int
    var averageHeartRate: Int
    var strokes: [Stroke]
    /// Ball speed in the first vs last third of the session (fatigue).
    var firstThirdAvgSpeed: Int
    var lastThirdAvgSpeed: Int

    init(session: SessionRecord, units: UnitSystem = .current) {
        speedUnit = units.speedUnit
        lengthUnit = units.lengthUnit
        func spd(_ kmh: Double) -> Int { Int(units.speed(kmh).rounded()) }
        func len(_ cm: Double) -> Double { (units.length(cm) * 10).rounded() / 10 }
        let shots = session.shots.filter { $0.type != .calibration }
        let all = ShotSummary(shots)
        durationMinutes = Int(session.duration / 60)
        totalShots = shots.count
        sweetSpotPercent = Int(all.sweetSpotPercent)
        pointsWon = session.pointsWon
        pointsLost = session.pointsLost
        averageHeartRate = Int(session.averageHeartRate)
        strokes = ShotType.allCases.compactMap { t in
            let s = shots.filter { $0.type == t }
            guard !s.isEmpty else { return nil }
            let m = ShotSummary(s)
            return Stroke(type: t.label, count: m.count, sweetSpotPercent: Int(m.sweetSpotPercent),
                          avgBallSpeed: spd(m.avgBallKmh), maxBallSpeed: spd(m.maxBallKmh), avgSwingSpeed: spd(m.avgSwingKmh),
                          avgSpinRPM: Int(m.avgSpinRPM), avgPathDeg: Int(m.avgPathAngle), avgFaceDeg: Int(m.avgFaceAngle),
                          avgContactTowardTip: len(m.avgImpactY),
                          avgContactRight: len(m.avgImpactX),
                          contactSpread: len(m.impactSpreadCm))
        }
        let third = max(shots.count / 3, 1)
        firstThirdAvgSpeed = spd(ShotSummary(Array(shots.prefix(third))).avgBallKmh)
        lastThirdAvgSpeed = spd(ShotSummary(Array(shots.suffix(third))).avgBallKmh)
    }

    var json: String {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        return String(data: (try? enc.encode(self)) ?? Data(), encoding: .utf8) ?? "{}"
    }
}

/// Something that can turn stats into words: Muse or the built-in template fallback.
@MainActor
protocol CoachEngine {
    var name: String { get }
    func summarize(_ digest: SessionDigest) async throws -> String
    func answer(_ question: String, digest: SessionDigest) async throws -> String
    func drill(_ digest: SessionDigest) async throws -> String
    func scout(_ digest: SessionDigest, opponent: ScoutOpponent?) async throws -> String
    func plan(_ digest: SessionDigest) async throws -> String
    func review(_ digest: SessionDigest) async throws -> String
}

/// An opponent's shared totals, rendered in the digest's display units.
/// Shared aggregates, never your racket's measurements.
struct ScoutOpponent: Codable, Sendable {
    var name: String
    var shots: Int
    var sweetPercent: Int
    var avgBall: Int?
    var topBall: Int?
    var speedUnit: String

    var block: String {
        "\(name): \(shots) shots, \(sweetPercent)% sweet spot" +
        (avgBall.map { ", avg \($0) \(speedUnit)" } ?? "") +
        (topBall.map { " (top \($0))" } ?? "")
    }
}

enum CoachPrompts {
    static let system = """
    You are Muse, the AI in Tennis Buddee, a smart tennis racket. You are upbeat and know tennis well. You are given measurements from a sensor in the \
    player's racket. Only use numbers that appear in the data; never invent stats. Speeds use the data's speedUnit, \
    spin is rpm, contact positions use lengthUnit from the sweet spot (positive toward the tip / to the right). \
    Always write the units next to numbers and never mention JSON field names. Keep answers short, \
    concrete and encouraging.
    """

    static func summary(_ d: SessionDigest) -> String {
        """
        Session data:
        \(d.json)

        Write a session report in under 120 words, no greeting. Start with one sentence on the overall session. \
        Then name the strongest stroke with two of its numbers and the weakest area with two of its numbers. \
        End with exactly 2 bullet-point tips. Each tip must cite a number from the data and give one concrete \
        technique cue (for example contact point, footwork, swing path or racket face). No generic advice.
        """
    }

    static func question(_ q: String, _ d: SessionDigest) -> String {
        "Session data:\n\(d.json)\n\nPlayer's question: \(q)\nAnswer in under 80 words using the data."
    }

    /// For the tool-using coach: no data in the prompt, it looks up what it needs.
    static func agentQuestion(_ q: String) -> String {
        "Player's question: \(q)\nLook up what you need with the tools: the session digest, individual shots, the racket's live sensors and status, " +
        "the player's notes and the what-if simulator. Answer in under 80 words."
    }

    static func drill(_ d: SessionDigest) -> String {
        """
        Session data:
        \(d.json)

        Design ONE short drill for the player's weakest stroke. Reply with exactly these three lines and nothing else:
        TITLE: <2 to 5 words>
        GOAL: <a number from 5 to 15> <stroke name in plural> <condition>
        WHY: <one sentence that cites one number from the data, with its unit>
        The condition must be exactly one of: "in the sweet spot", "over <number> rpm", "over <number> \(d.speedUnit)".
        Never mention data field names. Example:
        TITLE: Center the backhand
        GOAL: 10 backhands in the sweet spot
        WHY: Only 35% of your backhands hit the sweet spot.
        """
    }

    static func scout(_ d: SessionDigest, opponent: ScoutOpponent?) -> String {
        let opp = opponent.map {
            "Opponent's shared totals (given by the Together share, not measured by your racket):\n\($0.block)"
        } ?? "No shared opponent data: scout the player as an opponent would, using compare_sessions across their recent sessions."
        return """
        Your session data:
        \(d.json)

        \(opp)

        Write a match plan in under 120 words, no greeting. Start with one sentence on how you match up. \
        Then: the opponent's likely strength and weakness from their totals against your digest; one pattern to lean on; \
        one thing to avoid. End with a prep drill in exactly TITLE/GOAL/WHY lines \
        (GOAL: <5-15> <strokes> <condition>; condition one of "in the sweet spot", "over <number> rpm", "over <number> \(d.speedUnit)"). \
        Cite numbers with units. Say once that opponent numbers are shared totals, not your measurements.
        """
    }

    static func plan(_ d: SessionDigest) -> String {
        """
        Session data:
        \(d.json)

        Design a 3-step practice plan for the next session: weakest link first, a progression, then a rally count. \
        Reply in exactly this format and nothing else:
        PLAN: <title, 2 to 6 words>
        STEP 1:
        TITLE: <2 to 5 words>
        GOAL: <a number from 5 to 15> <stroke name in plural> <condition>
        WHY: <one sentence that cites one number from the data, with its unit>
        NOTE: <one sentence: what success feels like>
        STEP 2: (same four lines, a different weakness or a harder progression)
        STEP 3: (same four lines; a rally count, so the condition may instead be "any <number> <strokes>")
        Each condition must be exactly one of: "in the sweet spot", "over <number> rpm", "over <number> \(d.speedUnit)". \
        Never mention data field names.
        """
    }

    static func review(_ d: SessionDigest) -> String {
        """
        Session data:
        \(d.json)

        Review this session like an assistant coach. Reply with 1 to 4 flags in exactly this format per flag and nothing else:
        FLAG: <short label>
        DETAIL: <one sentence citing numbers with units>
        EVIDENCE: <which numbers, e.g. "thirds \(d.firstThirdAvgSpeed)->\(d.lastThirdAvgSpeed) \(d.speedUnit)" or "backhand 30% sweet">
        Skip praise; only flag what needs a human's eyes. If nothing needs review, reply with exactly one line: CLEAR: <one sentence>.
        """
    }
}

/// Deterministic offline coach, available without an API key or network connection.
struct TemplateCoach: CoachEngine {
    let name = "Built-in engine"

    func summarize(_ d: SessionDigest) async throws -> String {
        guard d.totalShots > 0 else { return "No shots recorded yet. Start a session and hit a few balls." }
        let best = d.strokes.max { $0.sweetSpotPercent < $1.sweetSpotPercent }
        let worst = d.strokes.min { $0.sweetSpotPercent < $1.sweetSpotPercent }
        var out = "\(d.totalShots) shots in \(max(d.durationMinutes, 1)) min with \(d.sweetSpotPercent)% in the sweet spot. "
        if let b = best {
            out += "Your \(b.type.lowercased()) led the way: \(b.sweetSpotPercent)% sweet spot, averaging \(b.avgBallSpeed) \(d.speedUnit) (top \(b.maxBallSpeed)). "
        }
        if let w = worst, w.type != best?.type {
            let dir = w.avgContactTowardTip >= 0 ? "toward the tip" : "toward the throat"
            out += "Your \(w.type.lowercased()) needs work: \(w.sweetSpotPercent)% sweet spot, contact drifting \(String(format: "%.1f", abs(w.avgContactTowardTip))) \(d.lengthUnit) \(dir). "
        }
        out += "\n\n• "
        if d.lastThirdAvgSpeed < d.firstThirdAvgSpeed - 3 {
            out += "Ball speed dropped from \(d.firstThirdAvgSpeed) to \(d.lastThirdAvgSpeed) \(d.speedUnit) late in the session; take short breaks to keep your legs fresh."
        } else {
            out += "You kept your pace all session (\(d.firstThirdAvgSpeed) → \(d.lastThirdAvgSpeed) \(d.speedUnit)). Nice consistency."
        }
        if let w = worst {
            out += "\n• On your \(w.type.lowercased()), "
            let near = d.lengthUnit == "cm" ? 1.0 : 0.4
            out += w.avgContactTowardTip > near ? "let the ball come a little deeper so you meet it in the center of the strings."
                : w.avgContactTowardTip < -near ? "step in and reach a little further so contact moves up toward the center."
                : "keep your eyes on contact a beat longer to tighten your \(w.contactSpread) \(d.lengthUnit) spread."
        }
        return out
    }

    func answer(_ question: String, digest d: SessionDigest) async throws -> String {
        let q = question.lowercased()
        if let s = d.strokes.first(where: { q.contains($0.type.lowercased()) }) {
            return "\(s.type): \(s.count) shots, \(s.sweetSpotPercent)% sweet spot, \(s.avgBallSpeed) \(d.speedUnit) average (top \(s.maxBallSpeed)), \(s.avgSpinRPM) rpm, swing path \(s.avgPathDeg)°."
        }
        return try await summarize(d)
    }

    func drill(_ d: SessionDigest) async throws -> String {
        let w = d.strokes.min { $0.sweetSpotPercent < $1.sweetSpotPercent }
        let stroke = w?.type ?? "Forehand"
        return "TITLE: Center the \(stroke)\nGOAL: 10 \(stroke.lowercased())s in the sweet spot\nWHY: Only \(w?.sweetSpotPercent ?? 0)% of your \(stroke.lowercased())s hit the sweet spot."
    }

    func scout(_ d: SessionDigest, opponent: ScoutOpponent?) async throws -> String {
        guard d.totalShots > 0 else { return "No shots recorded yet. Play first, then scout." }
        let w = d.strokes.min { $0.sweetSpotPercent < $1.sweetSpotPercent }
        guard let opp = opponent else {
            return "No shared opponent data, so here is how an opponent would scout you: attack your " +
                "\(w?.type.lowercased() ?? "second serve") (\(w?.sweetSpotPercent ?? 0)% sweet spot). " +
                "Lean on your strongest patterns early and protect the weaker side late."
        }
        let gap = opp.sweetPercent - d.sweetSpotPercent
        var out = "You hit \(d.sweetSpotPercent)% sweet spot against \(opp.name)'s shared \(opp.sweetPercent)%. "
        out += gap > 5 ? "They are cleaner off the ground: keep rallies short and take time away. "
            : gap < -5 ? "You are the cleaner ball-striker: extend rallies and make them hit one more ball. "
            : "You match up evenly on clean contact: the match turns on first strikes and depth. "
        if let avg = opp.avgBall {
            out += "Their shared average is \(avg) \(d.speedUnit) against your \(d.strokes.map(\.avgBallSpeed).max() ?? 0). "
        }
        out += "Opponent numbers are shared totals, not your measurements."
        return out
    }

    func plan(_ d: SessionDigest) async throws -> String {
        guard d.totalShots > 0 else {
            return "PLAN: First session\nSTEP 1:\nTITLE: Meet the ball\nGOAL: 10 forehands in the sweet spot\nWHY: No shots recorded yet.\nNOTE: Easy swings; listen for clean contact."
        }
        let w = d.strokes.min { $0.sweetSpotPercent < $1.sweetSpotPercent }
        let stroke = w?.type ?? "Forehand"
        let low = stroke.lowercased() + "s"
        let best = d.strokes.max { $0.sweetSpotPercent < $1.sweetSpotPercent }
        let bloc = best.map { "TITLE: Trust the \($0.type)\nGOAL: 8 \($0.type.lowercased())s over \($0.avgSpinRPM) rpm\nWHY: Your \($0.type.lowercased()) averages \($0.avgSpinRPM) rpm; hold that shape.\nNOTE: Heavy ball, same swing." }
            ?? "TITLE: Hold your shape\nGOAL: 8 \(low) over 1000 rpm\nWHY: Spin keeps the ball in play.\nNOTE: Brush up the back of the ball."
        return """
        PLAN: Fix the \(stroke)
        STEP 1:
        TITLE: Center the \(stroke)
        GOAL: 10 \(low) in the sweet spot
        WHY: Only \(w?.sweetSpotPercent ?? 0)% of your \(low) hit the sweet spot.
        NOTE: Quiet head at contact; the middle of the strings does the work.
        STEP 2:
        \(bloc)
        STEP 3:
        TITLE: Twenty-ball rally
        GOAL: any 20 \(low)
        WHY: You hit \(d.totalShots) shots this session; string them together.
        NOTE: Crosscourt and patient; depth over winners.
        """
    }

    func review(_ d: SessionDigest) async throws -> String {
        guard d.totalShots > 0 else { return "CLEAR: No shots recorded, nothing to review." }
        var flags: [String] = []
        if d.lastThirdAvgSpeed < d.firstThirdAvgSpeed - 3 {
            flags.append("FLAG: Late fade\nDETAIL: Ball speed dropped from \(d.firstThirdAvgSpeed) to \(d.lastThirdAvgSpeed) \(d.speedUnit) in the last third.\nEVIDENCE: thirds \(d.firstThirdAvgSpeed)->\(d.lastThirdAvgSpeed) \(d.speedUnit)")
        }
        if let w = d.strokes.min(by: { $0.sweetSpotPercent < $1.sweetSpotPercent }), w.sweetSpotPercent < 60 {
            flags.append("FLAG: \(w.type) contact\nDETAIL: Only \(w.sweetSpotPercent)% of \(w.type.lowercased())s found the sweet spot across \(w.count) shots.\nEVIDENCE: \(w.type.lowercased()) \(w.sweetSpotPercent)% sweet")
        }
        if d.pointsLost > d.pointsWon, d.pointsLost + d.pointsWon > 0 {
            flags.append("FLAG: Scoreboard leak\nDETAIL: Lost \(d.pointsLost) points against \(d.pointsWon) won.\nEVIDENCE: points \(d.pointsWon)-\(d.pointsLost)")
        }
        return flags.isEmpty ? "CLEAR: Steady session, nothing needs a review." : flags.joined(separator: "\n")
    }
}

@MainActor
@Observable
final class CoachModel {
    var isWorking = false
    private(set) var lastEngineName: String?
    private(set) var lastFallbackReason: String?
    /// Muse's last validated swing film, shown on the Muse home and set on the What-if sliders.
    var lastFilm: SwingFilm?
    /// Notes Muse saved while producing the last answer, shown under it so nothing is remembered silently.
    private(set) var lastRemembered: [String] = []
    /// Online coaching is available while signed in (the server holds the Muse key).
    private(set) var museAvailable = false
    var engineName: String { lastEngineName ?? (museEnabled && museAvailable ? "Muse Spark · online" : fallback.name) }
    var museEnabled: Bool {
        didSet { UserDefaults.standard.set(museEnabled, forKey: "coach.museEnabled"); lastEngineName = nil }
    }
    /// Lets Muse read the player's notes and add new ones. Off: notes stay on the device.
    var memoryEnabled: Bool {
        didSet { UserDefaults.standard.set(memoryEnabled, forKey: "coach.memoryEnabled") }
    }
    @ObservationIgnored private weak var app: AppModel?
    private let fallback = TemplateCoach()
    @ObservationIgnored private var transportProvider: @MainActor () async -> MuseTransport?

    init(transportProvider: @escaping @MainActor () async -> MuseTransport? = { nil }) {
        self.transportProvider = transportProvider
        museEnabled = UserDefaults.standard.object(forKey: "coach.museEnabled") as? Bool ?? true
        memoryEnabled = UserDefaults.standard.object(forKey: "coach.memoryEnabled") as? Bool ?? true
        if let data = UserDefaults.standard.data(forKey: "coach.activePlan") {
            activePlan = try? JSONDecoder().decode(PracticePlan.self, from: data)
        }
    }

    func connect(to app: AppModel) { self.app = app }
    func useTransport(_ provider: @escaping @MainActor () async -> MuseTransport?) { transportProvider = provider }
    func setSignedIn(_ signedIn: Bool) { museAvailable = signedIn }

    func summarize(_ session: SessionRecord) async -> String {
        let digest = SessionDigest(session: session)
        return await run(session: session) { try await $0.summarize(digest) }
    }

    func answer(_ q: String, session: SessionRecord) async -> String {
        let digest = SessionDigest(session: session)
        return await run(session: session) { try await $0.answer(q, digest: digest) }
    }

    func drill(_ session: SessionRecord) async -> String {
        let digest = SessionDigest(session: session)
        return await run(session: session) { try await $0.drill(digest) }
    }

    /// Match plan against a friend's shared totals (or a self-scout when nil).
    func scout(_ session: SessionRecord, opponent: SharedPlayerStats?, opponentName: String) async -> String {
        let digest = SessionDigest(session: session)
        let units = UnitSystem.current
        let opp = opponent.map {
            ScoutOpponent(name: opponentName, shots: $0.shots, sweetPercent: Int($0.sweetPercent),
                          avgBall: $0.averageBallKmh.map { Int(units.speed($0).rounded()) },
                          topBall: $0.topBallKmh.map { Int(units.speed($0).rounded()) },
                          speedUnit: units.speedUnit)
        }
        return await run(session: session) { try await $0.scout(digest, opponent: opp) }
    }

    /// The plan the UI shows; starting a step runs it as a drill (mirrored on Watch).
    var activePlan: PracticePlan? {
        didSet {
            if let plan = activePlan, let data = try? JSONEncoder().encode(plan) {
                UserDefaults.standard.set(data, forKey: "coach.activePlan")
            } else {
                UserDefaults.standard.removeObject(forKey: "coach.activePlan")
            }
        }
    }

    func plan(_ session: SessionRecord) async -> PracticePlan {
        let digest = SessionDigest(session: session)
        let text = await run(session: session) { try await $0.plan(digest) }
        let parsed = PracticePlan.parse(text, sessionID: session.id, engineName: lastEngineName ?? fallback.name)
        activePlan = parsed
        return parsed
    }

    func startPlanStep(_ step: PracticeStep) {
        app?.startDrill(step.drill)
    }

    /// Review a session for a human coach: flags are saved for the review queue.
    func review(_ session: SessionRecord) async -> CoachReview {
        let digest = SessionDigest(session: session)
        let text = await run(session: session) { try await $0.review(digest) }
        let parsed = ReviewFlag.parseAll(text)
        let record = CoachReview(sessionID: session.id, flags: parsed.flags, clearNote: parsed.clear ?? "",
                                 engineName: lastEngineName ?? fallback.name)
        if let context = app?.modelContext {
            context.insert(record)
            try? context.save()
        }
        return record
    }

    /// Muse picks and tests the change for a swing film. Needs Muse online; there is no offline director.
    func swingFilm(_ session: SessionRecord, stroke: ShotType) async -> Result<SwingFilm, Error> {
        guard !isWorking else { return .failure(MuseError.invalidResponse) }
        guard museEnabled, museAvailable, let transport = await transportProvider() else { return .failure(MuseError.signInRequired) }
        isWorking = true
        defer { isWorking = false }
        let app = self.app
        // Read-only here: the director doesn't offer remember_note.
        let memory = memoryEnabled ? app.flatMap { app in
            app.modelContext.map { CoachMemory.store($0, playerID: app.activePlayerID, sessionID: session.id) }
        } : nil
        let tools = CoachTools(current: session, app: app, memory: memory) {
            guard let context = app?.modelContext else { return [session] }
            return try context.fetch(FetchDescriptor<SessionRecord>(sortBy: [SortDescriptor(\.startDate)]))
        }
        do {
            let film = try await SwingFilmDirector(client: transport, tools: tools).direct(stroke)
            lastEngineName = "Muse Spark · online"
            lastFilm = film
            return .success(film)
        } catch {
            return .failure(error)
        }
    }

    private func run(session: SessionRecord, _ body: (CoachEngine) async throws -> String) async -> String {
        guard !isWorking else { return "Muse is already answering. Please try again shortly." }
        isWorking = true
        lastFallbackReason = nil
        lastRemembered = []
        defer { isWorking = false }
        if museEnabled, museAvailable, let transport = await transportProvider() {
            let app = self.app
            let memory = memoryEnabled ? app.flatMap { app in
                app.modelContext.map { context in
                    let store = CoachMemory.store(context, playerID: app.activePlayerID, sessionID: session.id)
                    return CoachMemory(notes: store.notes) { [weak self] text, category in
                        let note = try store.save(text, category)
                        self?.lastRemembered.append(text)
                        return note
                    }
                }
            } : nil
            let tools = CoachTools(current: session, app: app, memory: memory) {
                guard let context = app?.modelContext else { return [session] }
                return try context.fetch(FetchDescriptor<SessionRecord>(sortBy: [SortDescriptor(\.startDate)]))
            }
            let muse = MuseCoach(client: transport, tools: tools)
            do {
                let text = try await body(muse)
                lastEngineName = muse.name
                return text
            } catch {
                if Task.isCancelled { return "Cancelled." }
                lastFallbackReason = error.localizedDescription
            }
        }
        lastEngineName = fallback.name
        return (try? await body(fallback)) ?? "No answer is available right now."
    }
}
