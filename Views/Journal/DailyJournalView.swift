import SwiftUI
import SwiftData

struct DailyJournalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Trade.date, order: .forward) private var allTrades: [Trade]

    var existingJournal: DailyJournal?

    @State private var date: Date = Date()
    @State private var bias: MarketBias = .neutral
    @State private var mood: Int = 3
    @State private var keyLevels: String = ""
    @State private var preMarketPlan: String = ""
    @State private var postMarketReview: String = ""
    @State private var lessonsLearned: String = ""

    var isEditing: Bool { existingJournal != nil }

    var tradesForDay: [Trade] {
        allTrades.filter { $0.date.dayKey == date.dayKey }
    }

    var dayPnL: Double { tradesForDay.reduce(0) { $0 + $1.netPnL } }
    var dayStats: TradeStats { StatsCalculator.calculate(from: tradesForDay) }

    var body: some View {
        NavigationStack {
            Form {
                headerSection
                preMarketSection
                postMarketSection

                if !tradesForDay.isEmpty {
                    tradesSection
                }
            }
            .navigationTitle(isEditing ? "Edit Journal" : "Daily Journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Update" : "Save") { saveJournal() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear { loadExisting() }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        Section("Date & Overview") {
            DatePicker("Date", selection: $date, displayedComponents: .date)

            VStack(alignment: .leading, spacing: 8) {
                Text("Market Bias")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Picker("Bias", selection: $bias) {
                    ForEach(MarketBias.allCases, id: \.self) { b in
                        Label(b.rawValue, systemImage: b.systemImage).tag(b)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Mental State")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(moodLabel(mood))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Slider(value: Binding(
                    get: { Double(mood) },
                    set: { mood = Int($0) }
                ), in: 1...5, step: 1)
                .tint(moodColor(mood))
            }
            .padding(.vertical, 4)
        }
    }

    private var preMarketSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                Text("Key Levels")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextEditor(text: $keyLevels)
                    .frame(minHeight: 80)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Pre-Market Plan")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextEditor(text: $preMarketPlan)
                    .frame(minHeight: 100)
            }
        } header: {
            Label("Pre-Market", systemImage: "sunrise.fill")
        }
    }

    private var postMarketSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                Text("Post-Market Review")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextEditor(text: $postMarketReview)
                    .frame(minHeight: 100)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Lessons Learned")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextEditor(text: $lessonsLearned)
                    .frame(minHeight: 80)
            }
        } header: {
            Label("Post-Market", systemImage: "sunset.fill")
        }
    }

    private var tradesSection: some View {
        Section {
            HStack {
                Text("Net P&L")
                Spacer()
                Text(dayPnL.currency)
                    .fontWeight(.bold)
                    .foregroundStyle(dayPnL.pnlColor)
            }
            HStack {
                Text("Trades")
                Spacer()
                Text("\(dayStats.winningTrades)W / \(dayStats.losingTrades)L / \(dayStats.breakevenTrades)BE")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Win Rate")
                Spacer()
                Text(dayStats.winRate.percentage)
                    .foregroundStyle(.secondary)
            }

            ForEach(tradesForDay) { trade in
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(trade.displayInstrumentName) \(trade.directionEnum.rawValue)")
                            .font(.subheadline)
                        Text("\(trade.entryTime.shortTime) – \(trade.exitTime.shortTime)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(trade.netPnL.currency)
                        .fontWeight(.medium)
                        .foregroundStyle(trade.netPnL.pnlColor)
                }
                .font(.subheadline)
            }
        } header: {
            Label("Day's Trades", systemImage: "chart.bar")
        }
    }

    // MARK: - Helpers

    private func moodLabel(_ value: Int) -> String {
        switch value {
        case 1: return "Terrible"
        case 2: return "Poor"
        case 3: return "Okay"
        case 4: return "Good"
        case 5: return "Great"
        default: return "Okay"
        }
    }

    private func moodColor(_ value: Int) -> Color {
        switch value {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .mint
        case 5: return .green
        default: return .blue
        }
    }

    // MARK: - Save / Load

    private func saveJournal() {
        let journal = existingJournal ?? DailyJournal()
        journal.date = Calendar.current.startOfDay(for: date)
        journal.bias = bias.rawValue
        journal.mood = mood
        journal.keyLevels = keyLevels
        journal.preMarketPlan = preMarketPlan
        journal.postMarketReview = postMarketReview
        journal.lessonsLearned = lessonsLearned

        if existingJournal == nil {
            modelContext.insert(journal)
        }

        dismiss()
    }

    private func loadExisting() {
        guard let j = existingJournal else { return }
        date = j.date
        bias = j.biasEnum
        mood = j.mood
        keyLevels = j.keyLevels
        preMarketPlan = j.preMarketPlan
        postMarketReview = j.postMarketReview
        lessonsLearned = j.lessonsLearned
    }
}

#Preview {
    DailyJournalView(existingJournal: nil)
        .modelContainer(for: [Trade.self, DailyJournal.self], inMemory: true)
}
