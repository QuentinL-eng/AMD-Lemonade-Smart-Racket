import RacketKit
import SwiftData
import SwiftUI

/// Change one thing about your average stroke and see what the racket model estimates, or have Muse find the best
/// change. Same baseline and physics as Muse's `simulate_change` tool (`WhatIf`, `ShotSimulator`).
struct WhatIfView: View {
    @Query(sort: \SessionRecord.startDate) private var sessions: [SessionRecord]
    @Query(filter: #Predicate<WhatIfTrial> { $0.completedAt == nil }) private var pendingTrials: [WhatIfTrial]
    @Environment(CoachModel.self) private var coach
    @Environment(AppModel.self) private var model
    @Environment(\.modelContext) private var context
    @AppStorage(UnitSystem.storageKey) private var useMetric = false
    @State private var stroke = ShotType.forehand
    @State private var deltas = WhatIf.Deltas()
    @State private var lever = Lever.speed
    @State private var asked = ""
    @State private var answer = ""
    @State private var filmError = ""
    @State private var mode = SwingShow.Mode.auto
    private var units: UnitSystem { UnitSystem(metric: useMetric) }

    enum Lever: String, CaseIterable, Identifiable { case speed = "Speed", path = "Path", face = "Face", contact = "Contact"; var id: String { rawValue } }

    /// The latest session with at least one swing the model can start from.
    private var session: SessionRecord? { sessions.last { WhatIf.baseline($0.shots) != nil } }

    private func strokes(_ s: SessionRecord) -> [ShotType] {
        [.forehand, .backhand, .serve, .volley].filter { WhatIf.baseline(s.shots, type: $0) != nil }
    }

    var body: some View {
        Group {
            if let session, let type = currentStroke(session), let base = WhatIf.baseline(session.shots, type: type) {
                content(session, type: type, base: base)
            } else {
                ContentUnavailableView("No swings to test yet", systemImage: "slider.horizontal.3",
                    description: Text("Play a session with the racket's motion sensors on, then try changes here."))
            }
        }
        .navigationTitle("What if")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Reset", systemImage: "arrow.counterclockwise") { withAnimation { deltas = WhatIf.Deltas() } }
                    .disabled(deltas.isZero)
            }
        }
        .museScreen()
        .onAppear(perform: applyLastFilm)
    }

    private func currentStroke(_ s: SessionRecord) -> ShotType? {
        let available = strokes(s)
        return available.contains(stroke) ? stroke : available.first
    }

    /// Open on Muse's last film when there is one and nothing has been changed yet.
    private func applyLastFilm() {
        guard deltas.isZero, let film = coach.lastFilm, let session, strokes(session).contains(film.stroke) else { return }
        stroke = film.stroke
        deltas = film.deltas
    }

    /// Muse's film while its change is still on the levers.
    private func currentFilm(_ type: ShotType) -> SwingFilm? {
        coach.lastFilm.flatMap { $0.deltas == deltas && $0.stroke == type ? $0 : nil }
    }

    private func content(_ session: SessionRecord, type: ShotType, base: WhatIf.Baseline) -> some View {
        let impact = model.impactModel
        let after = WhatIf.apply(deltas, to: base.parameters)
        let b = ShotSimulator.simulate(base.parameters, model: impact), a = ShotSimulator.simulate(after, model: impact)
        let film = currentFilm(type)
        let available = strokes(session)
        return ScrollView {
            VStack(spacing: 0) {
                if available.count > 1 { strokeSwitcher(available, selected: type).padding(.horizontal, 16).padding(.bottom, 10) }
                SwingAnimationView(show: SwingShow(before: base.parameters, after: after, beforeBall: (b.ballSpeedKmh, b.spinRPM),
                                                   afterBall: (a.ballSpeedKmh, a.spinRPM), stroke: type, mode: mode),
                                   title: film?.title, mode: $mode)
                VStack(alignment: .leading, spacing: 12) {
                    if let film {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(film.cue).font(.headline).foregroundStyle(MuseStyle.text)
                            Text(film.why).font(.subheadline).foregroundStyle(MuseStyle.muted)
                        }
                    }
                    baselineLine(base, type: type, session: session)
                    leverTiles
                    leverEditor
                    results(before: b, after: a, film: film != nil)
                    tryItButton(session, type: type, before: b, after: a)
                    pendingTrialsSection()
                    askAbout(type, session: session)
                }
                .padding(16)
            }
        }
        .safeAreaInset(edge: .bottom) { bestChangeBar(session, type: type, film: film) }
        .sensoryFeedback(.selection, trigger: deltas)
        .animation(.snappy, value: deltas)
    }

    // MARK: Stroke and baseline

    private func strokeSwitcher(_ available: [ShotType], selected: ShotType) -> some View {
        HStack(spacing: 0) {
            ForEach(available) { t in
                Button {
                    stroke = t
                    deltas = WhatIf.Deltas()
                } label: {
                    Text(t.label).font(.footnote.weight(t == selected ? .bold : .semibold))
                        .foregroundStyle(t == selected ? MuseStyle.ink : MuseStyle.text.opacity(0.85))
                        .frame(maxWidth: .infinity, minHeight: 38)
                        .background(t == selected ? MuseStyle.text : .clear, in: .capsule)
                        .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(t == selected ? .isSelected : [])
            }
        }
        .padding(3)
        .background(MuseStyle.card, in: .capsule)
    }

    private func baselineLine(_ base: WhatIf.Baseline, type: ShotType, session: SessionRecord) -> some View {
        let p = base.parameters
        let face = p.faceAngleDeg >= 0 ? "\(Int(p.faceAngleDeg.rounded()))° open" : "\(Int(-p.faceAngleDeg.rounded()))° closed"
        let path = p.pathAngleDeg >= 0 ? "\(Int(p.pathAngleDeg.rounded()))° up" : "\(Int(-p.pathAngleDeg.rounded()))° down"
        return Text("Your average \(type.label.lowercased()): \(base.sampleCount) swings, \(units.speedText(p.swingSpeedKmh)), path \(path), face \(face), contact \(contactText(x: p.contactXcm, y: p.contactYcm)).")
            .font(.caption).foregroundStyle(MuseStyle.muted)
    }

    private func contactText(x: Double, y: Double) -> String {
        let d = (x * x + y * y).squareRoot()
        guard d >= 0.5 else { return "centered" }
        let dir = abs(y) >= abs(x) ? (y > 0 ? "toward tip" : "toward throat") : (x > 0 ? "right" : "left")
        return "\(units.lengthText(d)) \(dir)"
    }

    // MARK: Levers

    private func value(_ l: Lever) -> (text: String, changed: Bool) {
        func signed(_ v: Double, _ unit: String) -> String { v == 0 ? "0\(unit)" : "\(v > 0 ? "+" : "−")\(abs(v).formatted(.number.precision(.fractionLength(0...1))))\(unit)" }
        switch l {
        case .speed: return (signed(deltas.swingPercent, "%"), deltas.swingPercent != 0)
        case .path: return (signed(deltas.pathDeg, "°"), deltas.pathDeg != 0)
        case .face: return (signed(deltas.faceDeg, "°"), deltas.faceDeg != 0)
        case .contact:
            let d = (deltas.contactXcm * deltas.contactXcm + deltas.contactYcm * deltas.contactYcm).squareRoot()
            return (d == 0 ? "0 \(units.lengthUnit)" : units.lengthText(d), d != 0)
        }
    }

    private var leverTiles: some View {
        HStack(spacing: 8) {
            ForEach(Lever.allCases) { l in
                let v = value(l)
                Button { lever = l } label: {
                    VStack(spacing: 2) {
                        Text(l.rawValue).font(.caption2).foregroundStyle(MuseStyle.muted)
                        Text(v.text).font(.system(size: 17, weight: .bold, design: .rounded)).monospacedDigit()
                            .foregroundStyle(v.changed ? MuseStyle.lime : MuseStyle.text)
                    }
                    .frame(maxWidth: .infinity, minHeight: 72)
                    .background(lever == l ? MuseStyle.line : MuseStyle.card, in: .rect(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18)
                        .stroke(v.changed ? MuseStyle.lime : (lever == l ? MuseStyle.muted : MuseStyle.line), lineWidth: 2))
                    .contentShape(.rect(cornerRadius: 18))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(l.rawValue), \(v.text)")
                .accessibilityAddTraits(lever == l ? .isSelected : [])
            }
        }
    }

    @ViewBuilder private var leverEditor: some View {
        VStack(alignment: .leading, spacing: 14) {
            switch lever {
            case .speed:
                slider("Swing speed", value: $deltas.swingPercent, limit: WhatIf.Deltas.swingLimit, step: 1) {
                    $0 == 0 ? "same" : "\($0 > 0 ? "+" : "−")\(Int(abs($0)))%"
                }
            case .path:
                slider("Swing path", value: $deltas.pathDeg, limit: WhatIf.Deltas.angleLimit, step: 1) {
                    $0 == 0 ? "same" : "\(Int(abs($0)))° \($0 > 0 ? "more low-to-high" : "flatter")"
                }
            case .face:
                slider("Racket face", value: $deltas.faceDeg, limit: WhatIf.Deltas.angleLimit, step: 1) {
                    $0 == 0 ? "same" : "\(Int(abs($0)))° \($0 > 0 ? "more open" : "more closed")"
                }
            case .contact:
                slider("Tip ↔ throat", value: $deltas.contactYcm, limit: WhatIf.Deltas.contactLimit, step: 0.5) {
                    $0 == 0 ? "same" : "\(units.lengthText(abs($0))) toward \($0 > 0 ? "tip" : "throat")"
                }
                slider("Left ↔ right", value: $deltas.contactXcm, limit: WhatIf.Deltas.contactLimit, step: 0.5) {
                    $0 == 0 ? "same" : "\(units.lengthText(abs($0))) \($0 > 0 ? "right" : "left")"
                }
            }
        }
        .padding(16)
        .background(MuseStyle.card, in: .rect(cornerRadius: 22))
    }

    private func slider(_ title: String, value: Binding<Double>, limit: Double, step: Double,
                        text: @escaping (Double) -> String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(MuseStyle.text)
                Spacer()
                Text(text(value.wrappedValue)).font(.subheadline).foregroundStyle(MuseStyle.muted).monospacedDigit()
            }
            Slider(value: value, in: -limit...limit, step: step)
                .tint(MuseStyle.lime)
                .accessibilityLabel(title)
                .accessibilityValue(text(value.wrappedValue))
        }
    }

    // MARK: Results

    private func results(before b: ShotSimulator.Result, after a: ShotSimulator.Result, film: Bool) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            bar("Ball speed", before: units.speed(b.ballSpeedKmh), after: units.speed(a.ballSpeedKmh), unit: units.speedUnit)
            bar("Spin", before: b.spinRPM, after: a.spinRPM, unit: "rpm",
                note: a.spin == b.spin ? nil : "\(b.spin.label) → \(a.spin.label)")
            Text(film ? "Estimated by the racket's physics model. Picked and tested by Muse."
                      : "Estimated by the racket's physics model on your average swing. Ball flight isn't modeled.")
                .font(.caption).foregroundStyle(MuseStyle.muted)
        }
        .padding(16)
        .background(MuseStyle.card, in: .rect(cornerRadius: 22))
    }

    private func bar(_ label: String, before: Double, after: Double, unit: String, note: String? = nil) -> some View {
        let top = max(before, after, 1) * 1.15
        let up = after - before
        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(label).font(.subheadline).foregroundStyle(MuseStyle.text)
                Spacer()
                if abs(up) >= 0.5 { Text("\(Int(before.rounded())) → ").font(.subheadline).foregroundStyle(MuseStyle.muted) }
                Text("\(Int(after.rounded())) \(unit)").font(.subheadline.weight(.bold)).foregroundStyle(MuseStyle.text)
                    .monospacedDigit().contentTransition(.numericText())
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(MuseStyle.line)
                    Capsule().fill(MuseStyle.ghost).frame(width: geo.size.width * before / top)
                    if abs(up) >= 0.5 {
                        Capsule().fill(up > 0 ? MuseStyle.lime : Color(red: 1, green: 0.6, blue: 0.55))
                            .frame(width: geo.size.width * after / top).opacity(0.9)
                    }
                }
            }
            .frame(height: 10)
            .accessibilityHidden(true)
            if let note { Text(note).font(.caption.weight(.semibold)).foregroundStyle(MuseStyle.good) }
        }
    }

    // MARK: Trials

    /// Save the change on the levers so its estimate can be checked against measured play later.
    private func tryItButton(_ session: SessionRecord, type: ShotType, before: ShotSimulator.Result,
                             after: ShotSimulator.Result) -> some View {
        Button { saveTrial(session, type: type, before: before, after: after) } label: {
            Label("Try it: save this change to check later", systemImage: "flag")
                .font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.plain)
        .foregroundStyle(MuseStyle.text)
        .background(MuseStyle.card, in: .capsule)
        .disabled(deltas.isZero)
    }

    private func saveTrial(_ session: SessionRecord, type: ShotType, before: ShotSimulator.Result,
                           after: ShotSimulator.Result) {
        let measured = ShotSummary(WhatIf.usable(session.shots).filter { $0.type == type })
        let ups = [after.spinRPM > before.spinRPM * 1.05 ? "more spin" : nil,
                   after.ballSpeedKmh > before.ballSpeedKmh * 1.05 ? "more pace" : nil].compactMap { $0 }
        context.insert(WhatIfTrial(sessionID: session.id, stroke: type.rawValue,
            goal: ups.isEmpty ? "test a change" : ups.joined(separator: " + "), deltas: deltas,
            predicted: (before.ballSpeedKmh, after.ballSpeedKmh, before.spinRPM, after.spinRPM),
            measuredBefore: (measured.avgBallKmh, measured.avgSpinRPM)))
    }

    private func pendingTrialsSection() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if !pendingTrials.isEmpty {
                Text("Changes you are trying").font(.headline).foregroundStyle(MuseStyle.text)
                ForEach(pendingTrials.sorted { $0.createdAt < $1.createdAt }) { trial in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(trial.goal.capitalizedFirst).font(.subheadline.weight(.semibold))
                                .foregroundStyle(MuseStyle.text)
                            Text(WhatIf.describe(trial.deltas, units: units)).font(.caption)
                                .foregroundStyle(MuseStyle.muted)
                        }
                        Spacer()
                        if let session = followUpSession(for: trial) {
                            Button("Log follow-up") { logFollowUp(trial, session: session) }
                                .buttonStyle(.plain).font(.subheadline.weight(.semibold))
                                .foregroundStyle(MuseStyle.lime)
                        }
                    }
                    .padding(12)
                    .background(MuseStyle.card, in: .rect(cornerRadius: 18))
                }
            }
        }
    }

    /// The latest session with swings the trial's stroke can be measured on.
    private func followUpSession(for trial: WhatIfTrial) -> SessionRecord? {
        let stroke = ShotType(rawValue: trial.stroke)
        return sessions.last {
            !WhatIf.usable($0.shots).filter { stroke == nil || $0.type == stroke }.isEmpty
        }
    }

    private func logFollowUp(_ trial: WhatIfTrial, session: SessionRecord) {
        let stroke = ShotType(rawValue: trial.stroke)
        let measured = ShotSummary(WhatIf.usable(session.shots).filter { stroke == nil || $0.type == stroke })
        trial.complete(followUpSessionID: session.id, measuredBall: measured.avgBallKmh,
                       measuredSpin: measured.avgSpinRPM)
    }

    // MARK: Muse

    private func askAbout(_ type: ShotType, session: SessionRecord) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                ask("What if I \(WhatIf.describe(deltas, units: units)) on my \(type.label.lowercased())?", session)
            } label: {
                Label("Ask Muse about this change", systemImage: "questionmark.bubble")
                    .font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.plain)
            .foregroundStyle(MuseStyle.text)
            .background(MuseStyle.card, in: .capsule)
            .disabled(deltas.isZero || coach.isWorking)
            if !answer.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text(asked).font(.subheadline.weight(.bold)).foregroundStyle(MuseStyle.lime)
                    Text(answer).foregroundStyle(MuseStyle.text).textSelection(.enabled)
                    RememberedNotes()
                    Text(coach.engineName).font(.caption2).foregroundStyle(MuseStyle.muted)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(MuseStyle.card, in: .rect(cornerRadius: 22))
            }
        }
    }

    private func bestChangeBar(_ session: SessionRecord, type: ShotType, film: SwingFilm?) -> some View {
        VStack(spacing: 6) {
            if !filmError.isEmpty {
                Text(filmError).font(.caption).foregroundStyle(MuseStyle.muted).multilineTextAlignment(.center)
            } else if !coach.museAvailable {
                Text("Sign in under Racket → Account to have Muse find the best change.").font(.caption)
                    .foregroundStyle(MuseStyle.muted).multilineTextAlignment(.center)
            }
            Button { showBestChange(session, type: type) } label: {
                HStack(spacing: 8) {
                    if coach.isWorking { ProgressView().controlSize(.small).tint(MuseStyle.ink) } else { Image(systemName: "sparkles") }
                    Text(coach.isWorking ? "Muse is testing changes…" : film == nil ? "Show me the best change" : "Find another change")
                }
                .font(.headline).foregroundStyle(MuseStyle.ink)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(MuseStyle.lime.opacity(coach.museAvailable ? 1 : 0.4), in: .capsule)
            }
            .buttonStyle(.plain)
            .disabled(coach.isWorking || !coach.museAvailable)
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 8)
        .background(MuseStyle.background)
    }

    private func showBestChange(_ session: SessionRecord, type: ShotType) {
        filmError = ""
        Task {
            switch await coach.swingFilm(session, stroke: type) {
            case .success(let made):
                mode = .auto
                withAnimation { deltas = made.deltas }
            case .failure(let error):
                filmError = error.localizedDescription
            }
        }
    }

    private func ask(_ question: String, _ session: SessionRecord) {
        guard !coach.isWorking else { return }
        asked = question
        answer = ""
        Task { answer = await coach.answer(question, session: session) }
    }
}

/// "Muse remembered: …" under an answer, linking to the notes.
struct RememberedNotes: View {
    @Environment(CoachModel.self) private var coach

    var body: some View {
        if !coach.lastRemembered.isEmpty {
            NavigationLink { MemoryView() } label: {
                Label {
                    Text("Muse remembered: " + coach.lastRemembered.joined(separator: " · ")).font(.caption)
                } icon: { Image(systemName: "brain") }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
    }
}

extension String {
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}
