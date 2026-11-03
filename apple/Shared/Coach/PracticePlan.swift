import Foundation
import RacketKit

/// One step of a practice plan: a drill the Watch can count down, plus what success feels like.
struct PracticeStep: Codable, Sendable, Equatable, Identifiable {
    var id = UUID()
    var drill: Drill
    var note: String
}

/// A 3-step practice written from a session: weakest link first, a progression, then a rally count.
/// Steps reuse Drill, so starting one is the same path as any drill (tracked on-device, mirrored on Watch).
struct PracticePlan: Codable, Sendable, Equatable, Identifiable {
    var id = UUID()
    var title: String
    var createdAt: Date = Date()
    var sessionID: UUID
    var steps: [PracticeStep]
    /// Which engine wrote it, so the UI can name it like every other answer.
    var engineName: String

    /// Parses the plan reply ("PLAN: …" then "STEP n:" blocks each holding TITLE/GOAL/WHY/NOTE).
    /// Tolerant: keeps 1-4 non-empty steps, each parsed with Drill.parse.
    static func parse(_ text: String, sessionID: UUID, engineName: String = "") -> PracticePlan {
        func field(_ block: String, _ name: String) -> String {
            for line in block.components(separatedBy: .newlines) {
                let trimmed = line.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "*", with: "")
                if trimmed.uppercased().hasPrefix(name + ":") {
                    return String(trimmed.dropFirst(name.count + 1)).trimmingCharacters(in: .whitespaces)
                }
            }
            return ""
        }
        let title = field(text, "PLAN")
        var steps: [PracticeStep] = []
        let blocks = text.components(separatedBy: .newlines).split { line in
            let t = line.trimmingCharacters(in: .whitespaces).uppercased()
            return t.hasPrefix("STEP ") && t.hasSuffix(":")
        }
        for block in blocks.prefix(4) {
            let joined = block.joined(separator: "\n")
            guard joined.range(of: "GOAL:", options: .caseInsensitive) != nil else { continue }
            steps.append(PracticeStep(drill: Drill.parse(joined), note: field(joined, "NOTE")))
        }
        if steps.isEmpty {
            steps = [PracticeStep(drill: Drill.parse(text), note: "")]
        }
        return PracticePlan(title: title.isEmpty ? "Next practice" : title,
                            sessionID: sessionID, steps: steps, engineName: engineName)
    }
}
