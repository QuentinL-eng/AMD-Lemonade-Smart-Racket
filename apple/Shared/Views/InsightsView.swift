import Charts
import RacketKit
import SwiftData
import SwiftUI

/// The coach report for one session.
struct CoachCard: View {
    @Bindable var session: SessionRecord
    @Environment(CoachModel.self) private var coach

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                if session.coachSummary.isEmpty {
                    Text("Get a plain-language report on this session.")
                        .foregroundStyle(.secondary)
                } else {
                    Text(session.coachSummary).textSelection(.enabled)
                }
                HStack {
                    Button {
                        Task { session.coachSummary = await coach.summarize(session) }
                    } label: {
                        Label(session.coachSummary.isEmpty ? "Ask Muse" : "Regenerate", systemImage: "sparkles")
                    }
                    .buttonStyle(.borderedProminent)
                    .foregroundStyle(.black)
                    .disabled(coach.isWorking)
                    if coach.isWorking { ProgressView().controlSize(.small) }
                    Spacer()
                    Text(coach.engineName).font(.caption).foregroundStyle(.secondary)
                }
            }
        } label: {
            Label("Muse", systemImage: "sparkles")
        }
    }
}

// MARK: - Views

struct InsightsView: View {
    @Query(sort: \SessionRecord.startDate) private var records: [SessionRecord]
    @AppStorage(UnitSystem.storageKey) private var useMetric = false
    @State private var period = InsightPeriod.month
    @State private var stroke: ShotType?
    @State private var metric = InsightMetric.ballSpeed
    private var units: UnitSystem { UnitSystem(metric: useMetric) }

    private var sessions: [InsightSession] {
        records.filter { $0.summary.count > 0 }.map {
            InsightSession(id: $0.id, date: $0.startDate, duration: $0.duration,
                           averageHeartRate: $0.averageHeartRate, shots: $0.shots)
        }
    }

    private var model: InsightsModel {
        InsightsModel(sessions: sessions, period: period, stroke: stroke, metric: metric, units: units)
    }

    private let strokes: [ShotType?] = [nil, .forehand, .backhand, .serve, .volley]

    var body: some View {
        ScrollView {
            if sessions.isEmpty {
                coachRow.padding([.horizontal, .top])
                ContentUnavailableView("No data yet", systemImage: "chart.xyaxis.line",
                                       description: Text("Play a session and your trends show up here."))
            } else {
                let m = model
                VStack(alignment: .leading, spacing: 20) {
                    coachRow
                    strokeChips
                    metricTabs(m)
                    summary(m)
                    chart(m)
                    byStroke(m)
                    recent(m)
                }
                .padding()
            }
        }
        .navigationTitle("Insights")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Picker("Period", selection: $period) {
                        ForEach(InsightPeriod.allCases) { Text($0.label).tag($0) }
                    }
                } label: { Label(period.label, systemImage: "chevron.down").labelStyle(.titleAndIcon) }
            }
        }
        .onChange(of: records.count) { _, _ in if !model.hasHeartRate && metric == .heartRate { metric = .ballSpeed } }
    }

    private var strokeChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(strokes, id: \.self) { s in
                    let on = stroke == s
                    Button { stroke = s } label: {
                        Text(s?.label ?? "All")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 16).frame(minHeight: 44)
                            .foregroundStyle(on ? Color.black : Color.primary)
                            .background(on ? Color.accentColor : .clear, in: .capsule)
                            .overlay(Capsule().stroke(on ? .clear : Color.secondary.opacity(0.5)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
        }
    }

    private func metricTabs(_ m: InsightsModel) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(InsightMetric.allCases.filter { $0 != .heartRate || m.hasHeartRate }) { t in
                    Button { metric = t } label: {
                        VStack(spacing: 6) {
                            Text(t.label).font(.headline)
                                .foregroundStyle(metric == t ? Color.primary : Color.secondary)
                            Rectangle().fill(metric == t ? Color.accentColor : .clear).frame(height: 3)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(metric == t ? .isSelected : [])
                }
            }
        }
    }

    private func format(_ v: Double) -> String {
        switch metric {
        case .ballSpeed, .swingSpeed, .spin, .shots, .heartRate, .sweetSpot: String(format: "%.0f", v)
        case .face, .path, .contact: String(format: "%.1f", v)
        }
    }

    private func summary(_ m: InsightsModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let avg = m.periodAverage {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(format(avg)).font(.system(size: 56, weight: .bold, design: .rounded)).monospacedDigit()
                    Text(metric.unit(units)).font(.title3).foregroundStyle(.secondary)
                }
                if m.points.count > 1, let d = m.delta { deltaPill(d) }
                if let top = m.top, let low = m.low {
                    Text("Top \(format(top)) · Low \(format(low)) · vs previous period")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
            } else {
                Text("No data").font(.title2.bold()).foregroundStyle(.secondary)
            }
        }
    }

    private func deltaPill(_ d: Double) -> some View {
        let better: Bool? = {
            guard abs(d) >= 0.05, let dir = metric.betterDirection else { return nil }
            if dir == 0 { return nil }
            return (d > 0) == (dir > 0)
        }()
        let arrow = d > 0 ? "▲" : (d < 0 ? "▼" : "–")
        let word = better == true ? "better" : (better == false ? "worse" : "change")
        let color: Color = better == true ? Color(red: 0.37, green: 0.86, blue: 0.54)
            : (better == false ? Color(red: 1, green: 0.6, blue: 0.55) : .secondary)
        return Text("\(arrow) \(format(abs(d))) \(word)")
            .font(.subheadline.weight(.semibold)).foregroundStyle(color)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(color.opacity(0.18), in: .capsule)
    }

    @ViewBuilder private func chart(_ m: InsightsModel) -> some View {
        let pts = m.points
        card {
            if pts.isEmpty {
                Text(stroke.map { "No \($0.label.lowercased()) shots in this period" } ?? "No shots in this period")
                    .foregroundStyle(.secondary).frame(maxWidth: .infinity, minHeight: 120)
            } else if metric == .shots {
                Chart(pts) { p in
                    BarMark(x: .value("Session", p.date, unit: .day), y: .value("Shots", p.avg))
                        .foregroundStyle(Color.accentColor)
                }
                .frame(height: 210)
            } else {
                Chart(pts) { p in
                    if metric.isPerShot {
                        RuleMark(x: .value("Session", p.date, unit: .day),
                                 yStart: .value("Low", p.low), yEnd: .value("High", p.high))
                            .lineStyle(StrokeStyle(lineWidth: 16, lineCap: .round))
                            .foregroundStyle(Color.accentColor.opacity(0.28))
                    }
                    PointMark(x: .value("Session", p.date, unit: .day), y: .value("Average", p.avg))
                        .symbolSize(90).foregroundStyle(Color.accentColor)
                }
                .chartYAxisLabel(metric.unit(units))
                .frame(height: 210)
            }
        }
    }

    @ViewBuilder private func byStroke(_ m: InsightsModel) -> some View {
        let rows = m.byStroke
        if stroke == nil, !rows.isEmpty {
            card {
                VStack(alignment: .leading, spacing: 10) {
                    Text("By stroke").font(.headline)
                    Chart(rows, id: \.type) { r in
                        BarMark(x: .value("Average", r.avg), y: .value("Stroke", r.type.label))
                            .foregroundStyle(Color.accentColor)
                            .annotation(position: .trailing) { Text(format(r.avg)).font(.caption).foregroundStyle(.secondary) }
                    }
                    .frame(height: CGFloat(rows.count) * 40 + 20)
                }
            }
        }
    }

    private func recent(_ m: InsightsModel) -> some View {
        let last = Array(records.filter { $0.summary.count > 0 }.suffix(3).reversed())
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Sessions").font(.headline)
                Spacer()
                NavigationLink("All sessions") { HistoryView() }.font(.subheadline)
            }
            ForEach(last) { s in
                NavigationLink { SessionDetailView(session: s) } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(s.startDate.formatted(.dateTime.weekday().day().month())).font(.subheadline.weight(.semibold))
                            Text("\(s.summary.count) shots · \(Duration.seconds(s.duration).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated)))")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Avg \(units.speedText(s.summary.avgBallKmh))").font(.subheadline)
                            Text("Top \(units.speedText(s.summary.maxBallKmh))").font(.caption).foregroundStyle(.secondary)
                        }
                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                    }
                    .padding(14)
                    .background(.background.secondary, in: .rect(cornerRadius: 18))
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// First thing on Insights: the way into Muse, in the Muse section's own dark look.
    private var coachRow: some View {
        NavigationLink { CoachScreen() } label: {
            HStack(spacing: 14) {
                Image(systemName: "sparkles").font(.title3.weight(.semibold)).foregroundStyle(MuseStyle.ink)
                    .frame(width: 44, height: 44).background(MuseStyle.lime, in: .circle)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Muse").font(MuseStyle.display(20)).foregroundStyle(MuseStyle.text)
                    Text("Your best change, drills and questions").font(.caption).foregroundStyle(MuseStyle.muted)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.subheadline.weight(.semibold)).foregroundStyle(MuseStyle.lime)
            }
            .padding(14)
            .background(MuseStyle.background, in: .rect(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(MuseStyle.lime.opacity(0.35), lineWidth: 1))
            .contentShape(.rect(cornerRadius: 22))
        }
        .buttonStyle(.plain)
    }

    private func card<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        content().padding(16).background(.background.secondary, in: .rect(cornerRadius: 22))
    }
}
