import RacketKit
import SwiftData
import SwiftUI

extension SessionRecord {
    /// Real (non-calibration) shots, counted from the stored type so no shot JSON is decoded.
    /// `summary` decodes every shot, which stalls the UI on sessions with tens of thousands of hits.
    var playableShotCount: Int {
        (shotRecords ?? []).reduce(0) { $0 + ($1.typeRaw == ShotType.calibration.rawValue ? 0 : 1) }
    }
    var hasPlayableShots: Bool {
        (shotRecords ?? []).contains { $0.typeRaw != ShotType.calibration.rawValue }
    }
}

extension View {
    /// The Racket agent section's card: padded, dark, rounded.
    func museCard() -> some View {
        padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MuseStyle.card, in: .rect(cornerRadius: 22))
    }
}

/// Which engine wrote an answer, shown under every Racket agent feature.
struct EngineLabel: View {
    var name: String

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(name.hasPrefix("Racket agent") ? MuseStyle.good : MuseStyle.muted).frame(width: 6, height: 6)
            Text(name).font(.caption2).foregroundStyle(MuseStyle.muted)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Answered by \(name)")
    }
}

/// A match plan against a friend's shared racket totals, or a self-scout (how an opponent would play you).
struct ScoutView: View {
    /// The session to plan from; nil uses the newest session with shots.
    var session: SessionRecord?
    /// The friend's shared totals; nil runs a self-scout.
    var opponent: SharedPlayerStats?
    var opponentName = ""

    @Query(sort: \SessionRecord.startDate) private var sessions: [SessionRecord]
    @Environment(CoachModel.self) private var coach
    @State private var report = ""
    @State private var engine = ""

    private var source: SessionRecord? { session ?? sessions.last { $0.hasPlayableShots } }
    private var isSelfScout: Bool { opponent == nil }
    private var title: String { isSelfScout ? "Scout yourself" : "Scout \(opponentName)" }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(title).font(MuseStyle.display(30)).foregroundStyle(MuseStyle.text)
                Text(isSelfScout
                     ? "Racket agent reads your recent sessions the way an opponent would and predicts where they'd attack."
                     : "Racket agent sets your session against \(opponentName)'s shared racket totals and predicts how the match plays out.")
                    .font(.subheadline).foregroundStyle(MuseStyle.muted)
                if let opponent { opponentCard(opponent) }
                reportCard
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .navigationTitle("")
        .museScreen()
    }

    private func opponentCard(_ stats: SharedPlayerStats) -> some View {
        let units = UnitSystem.current
        return VStack(alignment: .leading, spacing: 10) {
            Text("\(opponentName.uppercased()) · SHARED TOTALS").font(MuseStyle.eyebrow).tracking(2)
                .foregroundStyle(MuseStyle.muted)
            HStack(spacing: 8) {
                StatTile(label: "Shots", value: "\(stats.shots)")
                StatTile(label: "Sweet spot", value: "\(Int(stats.sweetPercent))", unit: "%")
                if let avg = stats.averageBallKmh {
                    StatTile(label: "Avg ball", value: "\(Int(units.speed(avg).rounded()))", unit: units.speedUnit)
                }
            }
            Text("Shared by their racket, not measured by yours.").font(.caption2).foregroundStyle(MuseStyle.ghost)
        }
        .museCard()
    }

    @ViewBuilder private var reportCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MATCH PLAN").font(MuseStyle.eyebrow).tracking(2).foregroundStyle(MuseStyle.muted)
            if report.isEmpty {
                Text(source == nil ? "Play a session first, then scout." : "Racket agent writes a short plan: how you match up, what to lean on, what to avoid.")
                    .foregroundStyle(MuseStyle.text)
            } else {
                Text(report).foregroundStyle(MuseStyle.text).textSelection(.enabled)
            }
            Button(action: run) {
                HStack {
                    if coach.isWorking { ProgressView().controlSize(.small).tint(MuseStyle.ink) }
                    Text(report.isEmpty ? "Write the plan" : "Write it again")
                }
                .font(.subheadline.weight(.bold)).frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.plain)
            .foregroundStyle(MuseStyle.ink)
            .background(MuseStyle.lime, in: .capsule)
            .disabled(coach.isWorking || source == nil)
            .opacity(coach.isWorking || source == nil ? 0.6 : 1)
            EngineLabel(name: engine.isEmpty ? coach.engineName : engine)
        }
        .museCard()
    }

    private func run() {
        guard let source, !coach.isWorking else { return }
        Task {
            report = await coach.scout(source, opponent: opponent, opponentName: opponentName)
            engine = coach.engineName
        }
    }
}
