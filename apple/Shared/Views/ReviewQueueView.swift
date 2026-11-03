import RacketKit
import SwiftData
import SwiftUI

/// Session reviews waiting for a human's eyes: Muse flags what stood out, you approve or dismiss each one.
struct ReviewQueueView: View {
    @Query(sort: \CoachReview.createdAt, order: .reverse) private var reviews: [CoachReview]
    @Query(sort: \SessionRecord.startDate) private var sessions: [SessionRecord]
    @Environment(CoachModel.self) private var coach
    @Environment(\.modelContext) private var context

    private var latest: SessionRecord? { sessions.last { $0.hasPlayableShots } }
    private var pendingCount: Int { reviews.filter { $0.status == .pending }.count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .lastTextBaseline) {
                    Text("Review queue").font(MuseStyle.display(30)).foregroundStyle(MuseStyle.text)
                    Spacer()
                    if pendingCount > 0 {
                        Text("\(pendingCount) pending").font(.caption.weight(.semibold)).foregroundStyle(MuseStyle.lime)
                    }
                }
                Text("Muse flags the moments in a session that need a human look. Approve what you'll work on; dismiss the rest.")
                    .font(.subheadline).foregroundStyle(MuseStyle.muted)
                reviewButton
                if reviews.isEmpty {
                    Text("No reviews yet.").foregroundStyle(MuseStyle.muted).museCard()
                }
                ForEach(reviews) { review in card(review) }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .navigationTitle("")
        .museScreen()
    }

    private var reviewButton: some View {
        Button {
            guard let latest, !coach.isWorking else { return }
            Task { _ = await coach.review(latest) }
        } label: {
            HStack {
                if coach.isWorking { ProgressView().controlSize(.small).tint(MuseStyle.ink) }
                Text("Review this session")
            }
            .font(.subheadline.weight(.bold)).frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.plain)
        .foregroundStyle(MuseStyle.ink)
        .background(MuseStyle.lime, in: .capsule)
        .disabled(coach.isWorking || latest == nil)
        .opacity(coach.isWorking || latest == nil ? 0.6 : 1)
    }

    private func sessionLabel(_ id: UUID) -> String {
        guard let s = sessions.first(where: { $0.id == id }) else { return "Session" }
        return "\(s.startDate.formatted(.dateTime.weekday().day().month())) · \(s.playableShotCount) shots"
    }

    private func card(_ review: CoachReview) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(sessionLabel(review.sessionID).uppercased()).font(MuseStyle.eyebrow).tracking(1.5)
                    .foregroundStyle(MuseStyle.muted)
                Spacer()
                statusBadge(review.status)
            }
            if review.isClear {
                Label(review.clearNote.isEmpty ? "Nothing needs a review." : review.clearNote,
                      systemImage: "checkmark.seal")
                    .foregroundStyle(MuseStyle.good)
            } else {
                ForEach(review.flags) { flag in
                    VStack(alignment: .leading, spacing: 3) {
                        Label(flag.label, systemImage: "flag.fill").font(.headline).foregroundStyle(MuseStyle.text)
                        if !flag.detail.isEmpty { Text(flag.detail).foregroundStyle(MuseStyle.text) }
                        if !flag.evidence.isEmpty {
                            Text(flag.evidence).font(.caption.monospaced()).foregroundStyle(MuseStyle.muted)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            if review.status == .pending {
                HStack(spacing: 10) {
                    decisionButton("Approve", symbol: "checkmark", filled: true) { decide(review, .approved) }
                    decisionButton("Dismiss", symbol: "xmark", filled: false) { decide(review, .dismissed) }
                }
            } else if let at = review.reviewedAt {
                Text("\(review.status == .approved ? "Approved" : "Dismissed") \(at.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption).foregroundStyle(MuseStyle.muted)
            }
            EngineLabel(name: review.engineName.isEmpty ? coach.engineName : review.engineName)
        }
        .museCard()
    }

    private func statusBadge(_ status: CoachReview.Status) -> some View {
        let (text, color): (String, Color) = switch status {
        case .pending: ("Pending", MuseStyle.lime)
        case .approved: ("Approved", MuseStyle.good)
        case .dismissed: ("Dismissed", MuseStyle.ghost)
        }
        return Text(text).font(.caption2.weight(.bold)).foregroundStyle(color)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .overlay(Capsule().stroke(color.opacity(0.6)))
    }

    private func decisionButton(_ title: String, symbol: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol).font(.subheadline.weight(.bold)).frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.plain)
        .foregroundStyle(filled ? MuseStyle.ink : MuseStyle.text)
        .background(filled ? MuseStyle.lime : MuseStyle.line, in: .capsule)
    }

    private func decide(_ review: CoachReview, _ status: CoachReview.Status) {
        withAnimation { review.decide(status) }
        try? context.save()
    }
}
