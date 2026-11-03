import RacketKit
import SwiftData
import SwiftUI

/// A 3-step practice plan written from the newest session. Each step is a drill the Watch counts down.
struct PracticePlanView: View {
    @Query(sort: \SessionRecord.startDate) private var sessions: [SessionRecord]
    @Environment(CoachModel.self) private var coach
    @Environment(AppModel.self) private var model

    private var latest: SessionRecord? { sessions.last { $0.hasPlayableShots } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Practice plan").font(MuseStyle.display(30)).foregroundStyle(MuseStyle.text)
                Text("Three steps from your last session: the weakest link first, a progression, then a rally count.")
                    .font(.subheadline).foregroundStyle(MuseStyle.muted)
                if let plan = coach.activePlan {
                    planHeader(plan)
                    ForEach(Array(plan.steps.enumerated()), id: \.element.id) { index, step in
                        stepCard(step, number: index + 1)
                    }
                } else {
                    Text(latest == nil ? "Play a session first, then Muse writes a plan from it."
                         : "No plan yet. Muse writes one from your last session.")
                        .foregroundStyle(MuseStyle.text)
                        .museCard()
                }
                writeButton
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .navigationTitle("")
        .museScreen()
    }

    private func planHeader(_ plan: PracticePlan) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("PLAN · \(plan.createdAt.formatted(.dateTime.weekday().day().month()).uppercased())")
                .font(MuseStyle.eyebrow).tracking(2).foregroundStyle(MuseStyle.ink.opacity(0.7))
            Text(plan.title).font(MuseStyle.display(24)).foregroundStyle(MuseStyle.ink)
            Text(plan.engineName.isEmpty ? coach.engineName : plan.engineName)
                .font(.caption2).foregroundStyle(MuseStyle.ink.opacity(0.7))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MuseStyle.lime, in: .rect(cornerRadius: 22))
    }

    private func stepCard(_ step: PracticeStep, number: Int) -> some View {
        let running = model.activeDrill?.id == step.drill.id
        let progress = running ? model.activeDrill : nil
        return VStack(alignment: .leading, spacing: 8) {
            Text("STEP \(number)").font(MuseStyle.eyebrow).tracking(2).foregroundStyle(MuseStyle.muted)
            Text(step.drill.title).font(MuseStyle.display(20)).foregroundStyle(MuseStyle.text)
            Label(step.drill.goal, systemImage: "target").foregroundStyle(MuseStyle.text)
            if !step.drill.why.isEmpty { Text(step.drill.why).font(.caption).foregroundStyle(MuseStyle.muted) }
            if !step.note.isEmpty {
                Text(step.note).font(.callout.italic()).foregroundStyle(MuseStyle.text.opacity(0.85))
            }
            if let progress {
                ProgressView(value: Double(min(progress.completed, progress.target)), total: Double(max(progress.target, 1)))
                    .tint(MuseStyle.lime)
                Text("\(progress.completed) of \(progress.target)").font(.caption).foregroundStyle(MuseStyle.muted).monospacedDigit()
            }
            Button { coach.startPlanStep(step) } label: {
                Label(running ? (progress?.isDone == true ? "Step done" : "Running on Watch") : "Start",
                      systemImage: running ? "checkmark" : "applewatch")
                    .font(.subheadline.weight(.bold)).frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.plain)
            .foregroundStyle(MuseStyle.ink)
            .background(MuseStyle.lime, in: .capsule)
            .disabled(running)
            .opacity(running ? 0.6 : 1)
        }
        .museCard()
    }

    private var writeButton: some View {
        Button {
            guard let latest, !coach.isWorking else { return }
            Task { _ = await coach.plan(latest) }
        } label: {
            HStack {
                if coach.isWorking { ProgressView().controlSize(.small).tint(MuseStyle.lime) }
                Text(coach.activePlan == nil ? "Write my plan" : "Write a new plan")
            }
            .font(.subheadline.weight(.bold)).frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.plain)
        .foregroundStyle(MuseStyle.lime)
        .overlay(Capsule().stroke(MuseStyle.lime.opacity(0.6)))
        .disabled(coach.isWorking || latest == nil)
        .opacity(coach.isWorking || latest == nil ? 0.6 : 1)
    }
}
