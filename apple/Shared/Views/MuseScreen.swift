import RacketKit
import SwiftData
import SwiftUI

/// The Muse section's look ("Lab"): always dark, felt lime on near-black, rounded display type.
enum MuseStyle {
    static let background = Color(red: 0.063, green: 0.071, blue: 0.051)   // #10120D
    static let card = Color(red: 0.102, green: 0.114, blue: 0.082)         // #1A1D15
    static let line = Color(red: 0.149, green: 0.165, blue: 0.118)         // #262A1E
    static let stage = Color(red: 0.020, green: 0.024, blue: 0.016)        // #050604
    static let lime = Color(red: 0.867, green: 0.910, blue: 0.357)         // #DDE85B
    static let ink = Color(red: 0.067, green: 0.075, blue: 0.047)          // #11130C
    static let text = Color(red: 0.953, green: 0.961, blue: 0.925)         // #F3F5EC
    static let muted = Color(red: 0.663, green: 0.682, blue: 0.604)        // #A9AE9A
    static let ghost = Color(red: 0.486, green: 0.510, blue: 0.416)        // #7C826A
    static let good = Color(red: 0.369, green: 0.863, blue: 0.541)         // #5EDC8A

    static func display(_ size: CGFloat) -> Font { .system(size: size, weight: .heavy, design: .rounded) }
    static let eyebrow = Font.system(size: 11, weight: .semibold, design: .monospaced)
}

extension View {
    /// Dark Muse background, also under the navigation bar on iPhone.
    func museScreen() -> some View {
        background(MuseStyle.background.ignoresSafeArea())
            .environment(\.colorScheme, .dark)
            #if os(iOS)
            .toolbarBackground(MuseStyle.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            #endif
    }
}

/// Two swing trails, yours dashed and the change solid, through the ball: the hero card's picture.
struct SwingSketch: View {
    var color: Color

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            func curve(_ lift: CGFloat) -> Path {
                var p = Path()
                p.move(to: CGPoint(x: w * 0.06, y: h * (0.38 + lift)))
                p.addCurve(to: CGPoint(x: w * 0.82, y: h * (0.25 - lift * 1.6)),
                           control1: CGPoint(x: w * 0.25, y: h * (1.1 + lift)), control2: CGPoint(x: w * 0.62, y: h * (1.0 + lift)))
                return p
            }
            ctx.stroke(curve(0), with: .color(color.opacity(0.35)), style: StrokeStyle(lineWidth: 3, dash: [6, 7]))
            ctx.stroke(curve(0.1), with: .color(color), style: StrokeStyle(lineWidth: 6, lineCap: .round))
            let ball = CGRect(x: w * 0.71, y: h * 0.52, width: 20, height: 20)
            ctx.fill(Path(ellipseIn: ball), with: .color(Color(red: 0.984, green: 0.984, blue: 0.957)))
            ctx.stroke(Path(ellipseIn: ball), with: .color(color), lineWidth: 3)
        }
        .accessibilityHidden(true)
    }
}

/// Muse: the best change for your game, the next drill, memory, and questions, pushed from Insights.
struct CoachScreen: View {
    @Query(sort: \SessionRecord.startDate) private var sessions: [SessionRecord]
    @Query(sort: \CoachNote.updatedAt, order: .reverse) private var allNotes: [CoachNote]
    @Query(filter: #Predicate<CoachReview> { $0.statusRaw == "pending" }) private var pending: [CoachReview]
    @Environment(CoachModel.self) private var coach
    @Environment(AppModel.self) private var model
    @AppStorage(UnitSystem.storageKey) private var useMetric = false
    @State private var question = ""
    @State private var chat: [(q: String, a: String)] = []
    @State private var drill = ""
    @State private var filmError = ""
    @State private var openWhatIf = false
    private var units: UnitSystem { UnitSystem(metric: useMetric) }

    private var latest: SessionRecord? { sessions.last { $0.summary.count > 0 } }
    /// The newest session with motion shots, and its first stroke the swing film can draw.
    private var filmSource: (SessionRecord, ShotType)? {
        guard let s = sessions.last(where: { WhatIf.baseline($0.shots) != nil }),
              let t = SwingFilm.strokes.first(where: { WhatIf.baseline(s.shots, type: $0) != nil }) else { return nil }
        return (s, t)
    }
    /// The player's average for a stroke from the newest session that has it, as the What-if screen uses.
    private func baseline(_ stroke: ShotType) -> WhatIf.Baseline? {
        sessions.last { WhatIf.baseline($0.shots, type: stroke) != nil }.flatMap { WhatIf.baseline($0.shots, type: stroke) }
    }
    private var noteCount: Int { allNotes.filter { $0.playerID == model.activePlayerID }.count }
    private var pendingReviews: Int { pending.count }
    private var online: Bool { coach.museEnabled && coach.museAvailable }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                header
                hero
                HStack(spacing: 12) {
                    drillTile
                    memoryTile
                }
                if !drill.isEmpty { drillCard }
                whatIfRow
                featureRow(symbol: "list.number", title: "Practice plan",
                           detail: coach.activePlan.map { "\($0.title) · \($0.steps.count) steps" } ?? "Three steps from your last session") {
                    PracticePlanView()
                }
                featureRow(symbol: "binoculars", title: "Scout yourself",
                           detail: "Muse predicts where an opponent would attack") { ScoutView() }
                featureRow(symbol: "flag", title: "Review queue",
                           detail: pendingReviews == 0 ? "Flag a session for a human look" : "\(pendingReviews) waiting for you") {
                    ReviewQueueView()
                }
                askList
                ForEach(Array(chat.enumerated()), id: \.offset) { index, item in answerCard(item, last: index == chat.count - 1) }
                engineCard
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .safeAreaInset(edge: .bottom) { askBar }
        .navigationTitle("")
        .navigationDestination(isPresented: $openWhatIf) { WhatIfView() }
        .museScreen()
    }

    // MARK: Header and hero

    private var header: some View {
        HStack(alignment: .lastTextBaseline) {
            Text("Muse").font(MuseStyle.display(34)).foregroundStyle(MuseStyle.text)
            Spacer()
            HStack(spacing: 6) {
                Circle().fill(online ? MuseStyle.good : MuseStyle.muted).frame(width: 8, height: 8)
                Text(online ? "Muse Spark · online" : "Built-in engine").font(.caption).foregroundStyle(MuseStyle.muted)
            }
        }
        .padding(.top, 4)
    }

    /// Muse's best change for the player's own swing, or the button that asks for one.
    @ViewBuilder private var hero: some View {
        let film = coach.lastFilm
        let stroke = film?.stroke ?? filmSource?.1 ?? .forehand
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("BEST CHANGE · \(stroke.label.uppercased())").font(MuseStyle.eyebrow).tracking(2)
                    .foregroundStyle(MuseStyle.ink.opacity(0.7))
                Text(film?.title ?? "Find your best change").font(MuseStyle.display(30)).foregroundStyle(MuseStyle.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(film?.cue ?? "Muse tests changes on your average \(stroke.label.lowercased()) and shows you the one that helps most.")
                    .font(.subheadline).foregroundStyle(MuseStyle.ink.opacity(0.8))
            }
            .padding([.horizontal, .top], 18)
            SwingSketch(color: MuseStyle.ink).frame(height: 110)
            heroFooter(film)
        }
        .background(MuseStyle.lime, in: .rect(cornerRadius: 28))
        .clipShape(.rect(cornerRadius: 28))
        .contentShape(.rect(cornerRadius: 28))
        .onTapGesture { if film != nil { openWhatIf = true } }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(film != nil ? .isButton : [])
    }

    @ViewBuilder private func heroFooter(_ film: SwingFilm?) -> some View {
        HStack(spacing: 16) {
            if let film, let base = baseline(film.stroke) {
                let b = ShotSimulator.simulate(base.parameters, model: model.impactModel)
                let a = ShotSimulator.simulate(WhatIf.apply(film.deltas, to: base.parameters), model: model.impactModel)
                footerStat(String(format: "%+.0f%%", (a.ballSpeedKmh / max(b.ballSpeedKmh, 1) - 1) * 100), "ball speed")
                footerStat("\(Int(a.spinRPM.rounded()))", "rpm, was \(Int(b.spinRPM.rounded()))")
                Spacer()
                Text("Watch ›").font(.subheadline.weight(.bold)).foregroundStyle(MuseStyle.lime)
            } else if coach.isWorking {
                ProgressView().controlSize(.small).tint(MuseStyle.lime)
                Text("Muse is testing changes…").font(.subheadline).foregroundStyle(MuseStyle.text)
                Spacer()
            } else {
                Text(filmError.isEmpty ? (coach.museAvailable ? "Uses Muse Spark online" : "Sign in under Account to use Muse")
                     : filmError)
                    .font(.caption).foregroundStyle(MuseStyle.muted).lineLimit(2)
                Spacer()
                Button("Find it ›") { findBestChange() }
                    .font(.subheadline.weight(.bold)).foregroundStyle(MuseStyle.lime)
                    .disabled(!coach.museAvailable || filmSource == nil)
                    .frame(minHeight: 44)
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
        .background(MuseStyle.ink)
    }

    private func footerStat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value).font(MuseStyle.display(20)).foregroundStyle(MuseStyle.text).monospacedDigit()
            Text(label).font(.caption2).foregroundStyle(MuseStyle.muted)
        }
    }

    private func findBestChange() {
        guard let source = filmSource else { return }
        let (session, stroke) = source
        filmError = ""
        Task {
            if case .failure(let error) = await coach.swingFilm(session, stroke: stroke) { filmError = error.localizedDescription }
        }
    }

    // MARK: Tiles

    private var drillTile: some View {
        Button {
            guard let latest, model.activeDrill == nil else { return }
            Task { drill = await coach.drill(latest) }
        } label: {
            tile(symbol: "scope", title: model.activeDrill == nil ? "Next drill" : "Drill running",
                 detail: model.activeDrill?.goal ?? (latest == nil ? "Play a session first" : "Muse plans one for you"))
        }
        .buttonStyle(.plain)
        .disabled(coach.isWorking || latest == nil)
    }

    private var memoryTile: some View {
        NavigationLink { MemoryView() } label: {
            tile(symbol: "brain", title: "Memory", detail: noteCount == 1 ? "1 note Muse keeps" : "\(noteCount) notes Muse keeps")
        }
        .buttonStyle(.plain)
    }

    private var whatIfRow: some View {
        Button { openWhatIf = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "slider.horizontal.3").font(.title3).foregroundStyle(MuseStyle.lime)
                VStack(alignment: .leading, spacing: 2) {
                    Text("What if").font(.headline).foregroundStyle(MuseStyle.text)
                    Text("Try a change on your swing in 3D").font(.caption).foregroundStyle(MuseStyle.muted)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(MuseStyle.ghost)
            }
            .padding(14)
            .frame(minHeight: 60)
            .background(MuseStyle.card, in: .rect(cornerRadius: 22))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private func featureRow<D: View>(symbol: String, title: String, detail: String,
                                     @ViewBuilder destination: @escaping () -> D) -> some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 12) {
                Image(systemName: symbol).font(.title3).foregroundStyle(MuseStyle.lime).frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline).foregroundStyle(MuseStyle.text)
                    Text(detail).font(.caption).foregroundStyle(MuseStyle.muted).lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(MuseStyle.ghost)
            }
            .padding(14)
            .frame(minHeight: 60)
            .background(MuseStyle.card, in: .rect(cornerRadius: 22))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private func tile(symbol: String, title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: symbol).font(.title3).foregroundStyle(MuseStyle.lime)
            Spacer(minLength: 0)
            Text(title).font(.headline).foregroundStyle(MuseStyle.text)
            Text(detail).font(.caption).foregroundStyle(MuseStyle.muted).lineLimit(2).multilineTextAlignment(.leading)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 116, alignment: .leading)
        .background(MuseStyle.card, in: .rect(cornerRadius: 22))
    }

    private var drillCard: some View {
        let parsed = Drill.parse(drill)
        return VStack(alignment: .leading, spacing: 8) {
            Text("NEXT DRILL").font(MuseStyle.eyebrow).tracking(2).foregroundStyle(MuseStyle.muted)
            Text(parsed.title).font(MuseStyle.display(22)).foregroundStyle(MuseStyle.text)
            Text(parsed.goal).foregroundStyle(MuseStyle.text)
            if !parsed.why.isEmpty { Text(parsed.why).font(.caption).foregroundStyle(MuseStyle.muted) }
            Button {
                model.startDrill(parsed)
            } label: {
                Label(model.activeDrill?.title == parsed.title ? "Drill running" : "Start on Watch", systemImage: "applewatch")
                    .font(.subheadline.weight(.bold)).frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.plain)
            .foregroundStyle(MuseStyle.ink)
            .background(MuseStyle.lime, in: .capsule)
            .disabled(model.activeDrill?.title == parsed.title)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MuseStyle.card, in: .rect(cornerRadius: 22))
    }

    // MARK: Ask

    private static let suggestions = ["What's my weakest stroke?", "Am I getting tired?", "Show my last 5 off-center hits",
                                      "Is the racket working right?"]

    private var askList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ASK").font(MuseStyle.eyebrow).tracking(2).foregroundStyle(MuseStyle.muted).padding(.top, 4)
            VStack(spacing: 0) {
                ForEach(Array(Self.suggestions.enumerated()), id: \.offset) { index, s in
                    Button { ask(s) } label: {
                        HStack {
                            Text(s).foregroundStyle(MuseStyle.text)
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(MuseStyle.ghost)
                        }
                        .frame(minHeight: 48)
                        .padding(.horizontal, 16)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .disabled(coach.isWorking || latest == nil)
                    if index < Self.suggestions.count - 1 { MuseStyle.line.frame(height: 1) }
                }
            }
            .background(MuseStyle.card, in: .rect(cornerRadius: 22))
        }
    }

    private func answerCard(_ item: (q: String, a: String), last: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.q).font(.subheadline.weight(.bold)).foregroundStyle(MuseStyle.lime)
            Text(item.a).foregroundStyle(MuseStyle.text).textSelection(.enabled)
            if last {
                RememberedNotes()
                Text(coach.engineName).font(.caption2).foregroundStyle(MuseStyle.muted)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MuseStyle.card, in: .rect(cornerRadius: 22))
    }

    private var askBar: some View {
        HStack(spacing: 10) {
            TextField("Ask Muse anything about your game", text: $question)
                .textFieldStyle(.plain)
                .foregroundStyle(MuseStyle.text)
                .onSubmit { ask(question) }
            if coach.isWorking { ProgressView().controlSize(.small).tint(MuseStyle.lime) }
            Button { ask(question) } label: {
                Image(systemName: "arrow.up").font(.headline).foregroundStyle(MuseStyle.ink)
                    .frame(width: 44, height: 44).background(MuseStyle.lime, in: .circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Send")
            .disabled(question.trimmingCharacters(in: .whitespaces).isEmpty || coach.isWorking || latest == nil)
        }
        .padding(.leading, 18).padding(.trailing, 6).padding(.vertical, 6)
        .background(MuseStyle.card, in: .capsule)
        .padding(.horizontal, 16).padding(.vertical, 8)
        .background(MuseStyle.background)
    }

    private func ask(_ text: String) {
        let q = text.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty, !coach.isWorking, let latest else { return }
        question = ""
        Task { chat.append((q, await coach.answer(q, session: latest))) }
    }

    // MARK: Engine

    private var engineCard: some View {
        @Bindable var coach = coach
        return VStack(alignment: .leading, spacing: 8) {
            Toggle("Use Muse online", isOn: $coach.museEnabled)
                .disabled(!coach.museAvailable || coach.isWorking)
                .tint(MuseStyle.lime)
                .foregroundStyle(MuseStyle.text)
            Text(coach.museAvailable
                 ? "Muse sends your question and the shot data, racket readings and player notes it asks for to Baseten, which hosts Meta's open Muse Spark. Health data and session notes are excluded; turn off player notes under Memory."
                 : "Sign in under Account to use Muse online. Until then the built-in engine answers offline.")
                .font(.caption).foregroundStyle(MuseStyle.muted)
            if let reason = coach.lastFallbackReason {
                Text("Using the built-in engine: \(reason)").font(.caption).foregroundStyle(MuseStyle.muted)
            }
        }
        .padding(16)
        .background(MuseStyle.card, in: .rect(cornerRadius: 22))
        .padding(.top, 8)
    }
}
