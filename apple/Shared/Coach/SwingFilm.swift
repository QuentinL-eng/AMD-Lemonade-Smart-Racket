import Foundation
import RacketKit
import simd

/// A swing film: Muse picks one or two changes to the player's average stroke, tests them with `simulate_change`,
/// and hands back this short script. `SwingAnimationView` draws it with a fixed look, so Muse chooses the change and
/// the words, never the picture. Limits and rationale: docs/SWING_FILM.md (tools/swing_film.py is the same loop).
struct SwingFilm: Equatable {
    var stroke: ShotType
    var deltas: WhatIf.Deltas
    var title: String
    var cue: String
    var why: String

    /// Strokes the swing template can draw (a backhand is the forehand mirrored).
    static let strokes: [ShotType] = [.forehand, .backhand]

    enum Limits {
        /// Largest change, then smallest visible change, per lever.
        static let swingPercent = (15.0, 3.0), angle = (6.0, 2.0), path = (10.0, 2.0), contact = (3.0, 1.0)
        static let title = 24, cue = 60, why = 90
        static let banned = ["coach", "guarantee", "landing", "depth", "net", "injury", "pain", "always", "never"]
    }

    static let rules = """
        \nYou are directing a short swing film. A fixed renderer draws the player's average stroke, then the same swing \
        with your change, then the estimated before/after numbers. You only choose the change and three short texts. \
        Rules for make_swing_film: change one or two levers; swing_percent within -15...15 (at least 3 if used), face_deg \
        and path_deg within -6...6 and -10...10 (at least 2 if used), contact_x_cm and contact_y_cm within -3...3 (at \
        least 1 if used); the deltas must be exactly ones you already tested with simulate_change for the same stroke. \
        title up to 24 characters, cue up to 60, why up to 90; no digits in any text (the renderer shows the numbers). \
        The cue says what the player should feel, in plain words. Prefer the change with the biggest estimated gain that \
        a player can feel in one session. Do not mention landing, depth or the net.
        """

    static func prompt(_ stroke: ShotType) -> String {
        "Make my swing film for my \(stroke.rawValue): find the change that would help it most, test it with " +
        "simulate_change (type \(stroke.rawValue)), then call make_swing_film."
    }

    static let schema: [String: Any] = {
        func number(_ d: String) -> [String: Any] { ["type": "number", "description": d] }
        func text(_ n: Int, _ d: String) -> [String: Any] { ["type": "string", "description": "\(d) At most \(n) characters, no digits."] }
        return ["type": "function", "function": [
            "name": "make_swing_film",
            "description": "Render the swing film: the player's average swing, then the same swing with this change, then the simulated effect. Call once, after testing the change with simulate_change.",
            "parameters": ["type": "object", "additionalProperties": false,
                "required": ["stroke", "swing_percent", "face_deg", "path_deg", "contact_x_cm", "contact_y_cm", "title", "cue", "why"],
                "properties": [
                    "stroke": ["type": "string", "enum": strokes.map(\.rawValue)],
                    "swing_percent": number("Swing speed change, percent. 0 if unchanged."),
                    "face_deg": number("Face angle change, degrees (+ opens). 0 if unchanged."),
                    "path_deg": number("Path change, degrees (+ more low-to-high). 0 if unchanged."),
                    "contact_x_cm": number("Contact change across the strings, cm. 0 if unchanged."),
                    "contact_y_cm": number("Contact change toward the tip, cm. 0 if unchanged."),
                    "title": text(Limits.title, "Film title, e.g. 'Brush up the back'."),
                    "cue": text(Limits.cue, "What to feel on the next swings."),
                    "why": text(Limits.why, "Why this helps this player.")]]]]
    }()

    /// The deltas `simulate_change` actually applied, rounded so Muse's echo of them matches.
    struct Key: Hashable {
        var values: [Double]
        init(_ d: WhatIf.Deltas) {
            values = [d.swingPercent, d.faceDeg, d.pathDeg, d.contactXcm, d.contactYcm].map { ($0 * 1000).rounded() / 1000 }
        }
    }

    /// Checks a `make_swing_film` call. Returns the film, or every reason it was rejected.
    static func validate(_ args: [String: Any], stroke: ShotType, tested: Set<Key>) -> Result<SwingFilm, Rejection> {
        var errors: [String] = []
        if args["stroke"] as? String != stroke.rawValue { errors.append("stroke must be \(stroke.rawValue)") }
        func lever(_ key: String, _ limit: (Double, Double)) -> Double {
            guard let n = args[key] as? NSNumber, CFGetTypeID(n) != CFBooleanGetTypeID(), n.doubleValue.isFinite else {
                errors.append("\(key) must be a number"); return 0
            }
            let v = n.doubleValue
            if v != 0, !(limit.1...limit.0).contains(abs(v)) {
                errors.append("\(key)=\(v) must be 0 or between \(limit.1) and \(limit.0) in size")
            }
            return v
        }
        let d = WhatIf.Deltas(swingPercent: lever("swing_percent", Limits.swingPercent), faceDeg: lever("face_deg", Limits.angle),
                              pathDeg: lever("path_deg", Limits.path), contactXcm: lever("contact_x_cm", Limits.contact),
                              contactYcm: lever("contact_y_cm", Limits.contact))
        let used = [d.swingPercent, d.faceDeg, d.pathDeg, d.contactXcm, d.contactYcm].filter { $0 != 0 }.count
        if !(1...2).contains(used) { errors.append("change one or two levers, not \(used)") }
        if !tested.contains(Key(d)) { errors.append("these exact deltas were not tested with simulate_change for the \(stroke.rawValue)") }
        func text(_ key: String, _ limit: Int) -> String {
            guard let s = (args[key] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else {
                errors.append("\(key) is required"); return ""
            }
            if s.count > limit { errors.append("\(key) is \(s.count) characters; the limit is \(limit)") }
            if s.rangeOfCharacter(from: .decimalDigits) != nil { errors.append("\(key) must not contain digits") }
            let words = s.lowercased().split { !$0.isLetter }
            let hits = Limits.banned.filter { b in words.contains { $0.hasPrefix(b) } }
            if !hits.isEmpty { errors.append("\(key) must not use: \(hits.joined(separator: ", "))") }
            return s
        }
        let film = SwingFilm(stroke: stroke, deltas: d, title: text("title", Limits.title), cue: text("cue", Limits.cue),
                             why: text("why", Limits.why))
        return errors.isEmpty ? .success(film) : .failure(Rejection(reasons: errors))
    }

    struct Rejection: LocalizedError {
        var reasons: [String]
        var errorDescription: String? { "Muse's film didn't meet the limits: " + reasons.joined(separator: "; ") }
    }
}

/// Runs Muse until it hands back a valid film: digest, notes and `simulate_change` through `CoachTools`, then
/// `make_swing_film`, which is validated here. A rejected script goes back to Muse with the reasons, at most twice.
@MainActor
struct SwingFilmDirector {
    let client: MuseTransport
    let tools: CoachTools
    var maxRounds = 8

    private static let allowed: Set<String> = ["get_session_digest", "simulate_change", "recall_notes", "list_shots"]

    func direct(_ stroke: ShotType) async throws -> SwingFilm {
        let schemas = CoachTools.schemas.filter { Self.allowed.contains(($0["function"] as? [String: Any])?["name"] as? String ?? "") }
            + [SwingFilm.schema]
        var messages: [[String: Any]] = [["role": "system", "content": MuseCoach.systemPrompt + SwingFilm.rules],
                                         ["role": "user", "content": SwingFilm.prompt(stroke)]]
        var tested = Set<SwingFilm.Key>()
        var rejections = 0
        for _ in 0..<maxRounds {
            try Task.checkCancellation()
            let reply = try await client.complete(messages: messages, tools: schemas)
            let calls = reply["tool_calls"] as? [[String: Any]] ?? []
            guard calls.count <= 8 else { throw MuseError.roundLimit }
            messages.append(reply)
            if calls.isEmpty {
                messages.append(["role": "user", "content": "Call make_swing_film now with a change you tested."])
                continue
            }
            var film: SwingFilm?
            for call in calls {
                guard let id = call["id"] as? String, let f = call["function"] as? [String: Any],
                      let name = f["name"] as? String, let raw = f["arguments"] as? String else { throw MuseError.invalidResponse }
                let args = (try? JSONSerialization.jsonObject(with: Data(raw.utf8))) as? [String: Any] ?? [:]
                let output: String
                switch name {
                case "make_swing_film":
                    switch SwingFilm.validate(args, stroke: stroke, tested: tested) {
                    case .success(let made):
                        film = made
                        output = #"{"ok":true}"#
                    case .failure(let rejection):
                        rejections += 1
                        guard rejections <= 2 else { throw rejection }
                        output = try CoachTools.json(["error": "Film rejected: " + rejection.reasons.joined(separator: "; ") +
                                                      ". Fix these and call make_swing_film again."])
                    }
                case _ where Self.allowed.contains(name):
                    output = tools.execute(name: name, arguments: raw)
                    if name == "simulate_change", args["type"] as? String == stroke.rawValue,
                       let result = (try? JSONSerialization.jsonObject(with: Data(output.utf8))) as? [String: Any],
                       let a = result["applied_deltas"] as? [String: Double] {
                        tested.insert(SwingFilm.Key(WhatIf.Deltas(swingPercent: a["swing_percent"] ?? 0, faceDeg: a["face_deg"] ?? 0,
                            pathDeg: a["path_deg"] ?? 0, contactXcm: a["contact_x_cm"] ?? 0, contactYcm: a["contact_y_cm"] ?? 0)))
                    }
                default:
                    output = #"{"error":"Unknown tool."}"#
                }
                messages.append(["role": "tool", "tool_call_id": id, "content": output])
            }
            if let film { return film }
        }
        throw MuseError.roundLimit
    }
}

/// The swing template behind the What-if animation and Muse's swing films (docs/SWING_FILM.md). A fixed pivot (the
/// arm) turns the racket through contact; only the five racket numbers (speed, path, face, contact across/along)
/// shape it. The ball sits at the origin at contact and the target is +x. Metres, y up.
enum SwingTemplate {
    static let pivotToHead: Float = 1.1          // shoulder to string-bed centre at contact
    static let bedFromButt: Float = 0.512        // string-bed centre, as in RacketScene
    static let maxTurn: Float = 2.0              // radians either side of contact
    static let ballRadius: Float = 0.0335
    static let ballShown = 0.11                  // real seconds the ball stays after contact (no flight is modelled)

    struct Pose {
        var racket: simd_float4x4                // racket frame: x toward the tip, y across, z face normal; origin at the butt
        var bed: SIMD3<Float>                    // string-bed centre
        var normal: SIMD3<Float>
        var up: SIMD3<Float>                     // out of the swing plane, for the spin axis
    }

    /// Racket pose `t` real seconds from contact. A backhand is the same swing on the other side of the body.
    static func pose(_ p: ShotSimulator.Parameters, t: Double, backhand: Bool) -> Pose {
        let path = Float(p.pathAngleDeg) * .pi / 180, face = Float(p.faceAngleDeg) * .pi / 180
        let e1 = SIMD3<Float>(0, 0, backhand ? -1 : 1)                   // pivot -> head at contact
        let e2 = SIMD3<Float>(cos(path), sin(path), 0)                   // head travel at contact
        var n = simd_normalize(simd_cross(e1, e2))
        if n.y < 0 { n = -n }
        let omega = Float(p.swingSpeedKmh / 3.6) / pivotToHead
        let phi = maxTurn * tanh(omega * Float(t) / maxTurn)
        let r = cos(phi) * e1 + sin(phi) * e2                            // racket long axis
        let tangent = -sin(phi) * e1 + cos(phi) * e2
        let normal = cos(face) * tangent + sin(face) * n                 // + opens the face
        let across = simd_cross(normal, r)
        let head = -pivotToHead * e1 + pivotToHead * r
        // place the racket so the ball, at the origin at contact, meets the strings at the measured point
        let bed = head - (Float(p.contactXcm) * across + Float(p.contactYcm) * r) / 100
        let butt = bed - bedFromButt * r
        let m = simd_float4x4(columns: (SIMD4(r, 0), SIMD4(across, 0), SIMD4(normal, 0), SIMD4(butt, 1)))
        return Pose(racket: m, bed: bed, normal: normal, up: n)
    }
}
