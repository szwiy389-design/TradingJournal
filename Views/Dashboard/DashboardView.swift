import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Query(sort: \Trade.date, order: .reverse) private var trades: [Trade]
    @State private var selectedPeriod: StatsPeriod = .allTime
    @AppStorage("accountBalance") private var accountBalance: Double = 100000
    @AppStorage("customSetups") private var customSetupsRaw: String = ""
    @AppStorage("dailyLossLimit") private var dailyLossLimit: Double = 0.0

    enum StatsPeriod: String, CaseIterable {
        case today = "Today"
        case thisWeek = "Week"
        case thisMonth = "Month"
        case allTime = "All Time"

        var startDate: Date? {
            let cal = Calendar.current
            switch self {
            case .today: return cal.startOfDay(for: Date())
            case .thisWeek: return cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))
            case .thisMonth: return cal.date(from: cal.dateComponents([.year, .month], from: Date()))
            case .allTime: return nil
            }
        }
    }

    var filteredTrades: [Trade] {
        guard let start = selectedPeriod.startDate else { return trades }
        return trades.filter { $0.date >= start }
    }

    var stats: TradeStats {
        StatsCalculator.calculate(from: filteredTrades)
    }

    var equityCurve: [(date: Date, value: Double)] {
        StatsCalculator.equityCurve(from: filteredTrades)
    }

    var dailyPnLData: [DailyPnL] {
        StatsCalculator.dailyPnL(from: filteredTrades)
    }

    var hourlyPnLData: [HourlyPnL] {
        StatsCalculator.hourlyPnL(from: filteredTrades)
    }

    var todayPnL: Double {
        let start = Calendar.current.startOfDay(for: Date())
        return trades.filter { $0.date >= start }.reduce(0) { $0 + $1.netPnL }
    }

    var isLimitBreached: Bool {
        dailyLossLimit > 0 && todayPnL <= -dailyLossLimit
    }

    var weekTrades: [Trade] {
        let cal = Calendar.current
        guard let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))
        else { return [] }
        return trades.filter { $0.date >= weekStart }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Daily Loss Limit Alert
                    if isLimitBreached {
                        dailyLossAlert
                    }

                    // Period selector
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(StatsPeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Total P&L Card
                    totalPnLCard

                    // Stats Grid
                    statsGrid

                    // Equity Curve
                    if !equityCurve.isEmpty {
                        equityCurveChart
                    }

                    // Daily P&L Bar Chart
                    if !dailyPnLData.isEmpty {
                        dailyPnLChart
                    }

                    // Hourly P&L Bar Chart
                    if !hourlyPnLData.isEmpty {
                        hourlyPnLChart
                    }

                    // Setup Performance
                    let setupStats = StatsCalculator.setupStats(from: filteredTrades)
                    setupPerformanceSection(setupStats)

                    // Weekly Recap
                    weeklyRecap
                }
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image("TJLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 28)
                        Text("Trading Journal")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
    }

    // MARK: - Daily Loss Alert

    private var dailyLossAlert: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily Loss Limit Reached")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("Stop trading and protect your capital.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                }
            }

            Divider().background(.white.opacity(0.3))

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today's P&L")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                    Text(todayPnL.currency)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Limit")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                    Text("-\(dailyLossLimit.currency)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
            }

            Text("Take a break. Review your trades in the journal. Come back tomorrow.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.red.gradient)
                .shadow(color: .red.opacity(0.4), radius: 8, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    // MARK: - Total P&L Card

    private var totalPnLCard: some View {
        VStack(spacing: 8) {
            Text("Net P&L")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(stats.totalPnL.currency)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(stats.totalPnL.pnlColor)

            HStack(spacing: 16) {
                Label("\(stats.totalTrades) trades", systemImage: "chart.bar.fill")
                Label("\(stats.tradingDays) days", systemImage: "calendar")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(
                title: "Win Rate",
                value: stats.winRate.percentage,
                subtitle: "\(stats.winningTrades)W / \(stats.losingTrades)L",
                color: stats.winRate >= 0.5 ? .green : .red
            )
            StatCard(
                title: "Profit Factor",
                value: stats.profitFactor == .infinity ? "∞" : stats.profitFactor.formatted2,
                subtitle: "Gross P / Gross L",
                color: stats.profitFactor >= 1.5 ? .green : stats.profitFactor >= 1.0 ? .orange : .red
            )
            StatCard(
                title: "Avg Win",
                value: stats.avgWin.currency,
                subtitle: "Per winning trade",
                color: .green
            )
            StatCard(
                title: "Avg Loss",
                value: stats.avgLoss.currency,
                subtitle: "Per losing trade",
                color: .red
            )
            StatCard(
                title: "Avg Daily P&L",
                value: stats.avgDailyPnL.currency,
                subtitle: "Per trading day",
                color: stats.avgDailyPnL.pnlColor
            )
            StatCard(
                title: "Max Drawdown",
                value: stats.maxDrawdown.currency,
                subtitle: "Peak to trough",
                color: .orange
            )
            StatCard(
                title: "Largest Win",
                value: stats.largestWin.currency,
                subtitle: "Single trade",
                color: .green
            )
            StatCard(
                title: "Largest Loss",
                value: stats.largestLoss.currency,
                subtitle: "Single trade",
                color: .red
            )
            StatCard(
                title: "Expectancy",
                value: stats.expectancy.currency,
                subtitle: "Per trade avg",
                color: stats.expectancy.pnlColor
            )
            StatCard(
                title: "Risk/Reward",
                value: String(format: "%.2f", stats.riskRewardRatio),
                subtitle: "Avg win / avg loss",
                color: stats.riskRewardRatio >= 1.5 ? .green : .orange
            )
        }
        .padding(.horizontal)
    }

    // MARK: - Equity Curve

    private var equityCurveChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Equity Curve")
                .font(.headline)
                .padding(.horizontal)

            Chart {
                ForEach(Array(equityCurve.enumerated()), id: \.offset) { _, point in
                    LineMark(
                        x: .value("Trade", point.date),
                        y: .value("P&L", point.value)
                    )
                    .foregroundStyle(stats.totalPnL >= 0 ? Color.green : Color.red)
                    .interpolationMethod(.monotone)
                }

                RuleMark(y: .value("Zero", 0))
                    .foregroundStyle(.secondary.opacity(0.5))
                    .lineStyle(StrokeStyle(dash: [4, 4]))
            }
            .frame(height: 180)
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // MARK: - Daily P&L Bar Chart

    private var dailyPnLChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily P&L")
                .font(.headline)
                .padding(.horizontal)

            Chart(dailyPnLData.suffix(20)) { day in
                BarMark(
                    x: .value("Date", day.date, unit: .day),
                    y: .value("P&L", day.pnl)
                )
                .foregroundStyle(day.pnl >= 0 ? Color.green.opacity(0.8) : Color.red.opacity(0.8))
            }
            .frame(height: 150)
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // MARK: - Hourly P&L Chart

    private var hourlyPnLChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("P&L by Hour")
                .font(.headline)
                .padding(.horizontal)

            Chart(hourlyPnLData) { entry in
                BarMark(
                    x: .value("Hour", entry.label),
                    y: .value("P&L", entry.pnl)
                )
                .foregroundStyle(entry.pnl >= 0 ? Color.green.opacity(0.8) : Color.red.opacity(0.8))
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisValueLabel()
                        .font(.system(size: 9))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine()
                        .foregroundStyle(Color.secondary.opacity(0.2))
                    AxisValueLabel()
                        .font(.system(size: 10))
                }
            }
            .frame(height: 160)
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // MARK: - Setup Performance

    @ViewBuilder
    private func setupPerformanceSection(_ setups: [SetupStats]) -> some View {
        let hasSetups = !customSetupsRaw.isEmpty
        if setups.isEmpty && !hasSetups {
            setupEmptyState
        } else if !setups.isEmpty {
            setupPerformance(setups)
        }
    }

    private var setupEmptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("No setups defined yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            NavigationLink(destination: SettingsView()) {
                Label("Add your first setup", systemImage: "plus")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.green)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private func setupPerformance(_ setups: [SetupStats]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Setup Performance")
                .font(.headline)
                .padding(.horizontal)
                .padding(.bottom, 12)

            ForEach(Array(setups.enumerated()), id: \.element.id) { index, setup in
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        // Rank badge
                        Text("\(index + 1)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                            .frame(width: 18)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(setup.setup)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            HStack(spacing: 6) {
                                Text("\(setup.count) trades")
                                Text("·")
                                Text("\(setup.winRate.percentage) WR")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(setup.totalPnL.currency)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(setup.totalPnL.pnlColor)
                            Text("avg \(setup.avgPnL.currency)")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)

                    if index < setups.count - 1 {
                        Divider().padding(.leading, 46)
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

// MARK: - Weekly Recap Component

extension DashboardView {

    private var weeklyRecap: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Label("Weekly Recap", systemImage: "calendar.badge.clock")
                    .font(.headline)
                Spacer()
                Text(weekRangeLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, 14)
            .padding(.bottom, 12)

            if weekTrades.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "moon.zzz")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary)
                    Text("No trading activity this week.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                Divider().padding(.horizontal)
                weeklyStatsGrid
                Divider().padding(.horizontal)
                weeklyBestWorst
                Divider().padding(.horizontal)
                weeklyDisciplineScore
            }
        }
        .padding(.bottom, 14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private var weekRangeLabel: String {
        let cal = Calendar.current
        guard let start = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())),
              let end = cal.date(byAdding: .day, value: 6, to: start)
        else { return "" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return "\(fmt.string(from: start)) – \(fmt.string(from: end))"
    }

    private var weeklyStatsGrid: some View {
        let stats = StatsCalculator.calculate(from: weekTrades)
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            weekStat(label: "Net P&L", value: stats.totalPnL.currency, color: stats.totalPnL.pnlColor)
            weekStat(label: "Win Rate", value: stats.winRate.percentage, color: stats.winRate >= 0.5 ? .green : .red)
            weekStat(label: "Trades", value: "\(stats.totalTrades)", color: .primary)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    private func weekStat(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var weeklyBestWorst: some View {
        let best  = weekTrades.max(by: { $0.netPnL < $1.netPnL })
        let worst = weekTrades.min(by: { $0.netPnL < $1.netPnL })
        return VStack(spacing: 0) {
            if let b = best {
                tradeHighlightRow(
                    icon: "trophy.fill", iconColor: .yellow,
                    label: "Best Trade",
                    detail: "\(b.displayInstrumentName) · \(b.setup)",
                    value: b.netPnL.currency, valueColor: .green
                )
            }
            if let w = worst {
                tradeHighlightRow(
                    icon: "arrow.down.circle.fill", iconColor: .red,
                    label: "Worst Trade",
                    detail: "\(w.displayInstrumentName) · \(w.setup)",
                    value: w.netPnL.currency, valueColor: .red
                )
            }
        }
    }

    private func tradeHighlightRow(icon: String, iconColor: Color, label: String, detail: String, value: String, valueColor: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(detail)
                    .font(.subheadline)
                    .lineLimit(1)
            }
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(valueColor)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var weeklyDisciplineScore: some View {
        let score = disciplineScore(from: weekTrades)
        let color: Color = score >= 80 ? .green : score >= 50 ? .orange : .red
        let label: String = score >= 80 ? "Excellent" : score >= 50 ? "Needs work" : "Poor"

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Discipline Score")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(color)
            }
            Spacer()
            ZStack {
                Circle()
                    .stroke(Color(.systemFill), lineWidth: 6)
                    .frame(width: 52, height: 52)
                Circle()
                    .trim(from: 0, to: CGFloat(score) / 100)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 52, height: 52)
                    .rotationEffect(.degrees(-90))
                Text("\(score)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(color)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    /// Score 0–100. Starts at 100, deducted for negative tags, boosted for positive tags.
    private func disciplineScore(from trades: [Trade]) -> Int {
        guard !trades.isEmpty else { return 100 }
        var score = 100.0
        let negativeTags: Set<String> = ["FOMO", "Revenge Trading", "Greed", "Early Exit", "Hesitation", "Over-trading"]
        let positiveTags: Set<String> = ["Disciplined", "Patient", "Followed Plan", "Perfect Entry"]
        for trade in trades {
            for tag in trade.tags {
                if negativeTags.contains(tag) { score -= 8 }
                if positiveTags.contains(tag) { score += 4 }
            }
        }
        return max(0, min(100, Int(score)))
    }
}

// MARK: - Stat Card Component

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Trade.self, DailyJournal.self], inMemory: true)
}
