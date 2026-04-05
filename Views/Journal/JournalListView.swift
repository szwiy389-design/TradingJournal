import SwiftUI
import SwiftData

struct JournalListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyJournal.date, order: .reverse) private var journals: [DailyJournal]
    @Query(sort: \Trade.date, order: .reverse) private var trades: [Trade]
    @State private var showingNewJournal = false
    @State private var selectedDate = Date()

    var todayJournal: DailyJournal? {
        journals.first { Calendar.current.isDateInToday($0.date) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if journals.isEmpty {
                    emptyState
                } else {
                    journalList
                }
            }
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewJournal = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingNewJournal) {
                DailyJournalView(existingJournal: nil)
            }
        }
    }

    // MARK: - Journal List

    private var journalList: some View {
        List {
            // Quick access to today
            if let today = todayJournal {
                Section("Today") {
                    NavigationLink(destination: DailyJournalView(existingJournal: today)) {
                        JournalRowView(journal: today, trades: tradesForDate(today.date))
                    }
                }
            } else {
                Section {
                    Button {
                        showingNewJournal = true
                    } label: {
                        Label("Write today's journal", systemImage: "pencil.and.list.clipboard")
                    }
                } header: {
                    Text("Today")
                }
            }

            // Past journals
            let pastJournals = journals.filter { !Calendar.current.isDateInToday($0.date) }
            if !pastJournals.isEmpty {
                Section("Previous Entries") {
                    ForEach(pastJournals) { journal in
                        NavigationLink(destination: DailyJournalView(existingJournal: journal)) {
                            JournalRowView(journal: journal, trades: tradesForDate(journal.date))
                        }
                    }
                    .onDelete(perform: deleteJournals)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed.circle")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("No Journal Entries")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Write a pre-market plan and post-market review to improve your trading")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Write Today's Journal") {
                showingNewJournal = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    // MARK: - Helpers

    private func tradesForDate(_ date: Date) -> [Trade] {
        let key = date.dayKey
        return trades.filter { $0.date.dayKey == key }
    }

    private func deleteJournals(at offsets: IndexSet) {
        let past = journals.filter { !Calendar.current.isDateInToday($0.date) }
        for index in offsets {
            modelContext.delete(past[index])
        }
    }
}

// MARK: - Journal Row View

struct JournalRowView: View {
    let journal: DailyJournal
    let trades: [Trade]

    var dayPnL: Double { trades.reduce(0) { $0 + $1.netPnL } }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(journal.dateString)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                if !trades.isEmpty {
                    Text(dayPnL.currency)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(dayPnL.pnlColor)
                }
            }

            HStack(spacing: 12) {
                // Bias badge
                Label(journal.biasEnum.rawValue, systemImage: journal.biasEnum.systemImage)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(biasColor(journal.biasEnum).opacity(0.15))
                    .foregroundStyle(biasColor(journal.biasEnum))
                    .clipShape(Capsule())

                // Mood
                Text("Mood: \(journal.moodEmoji)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !trades.isEmpty {
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text("\(trades.count) trade\(trades.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !journal.preMarketPlan.isEmpty {
                Text(journal.preMarketPlan)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }

    private func biasColor(_ bias: MarketBias) -> Color {
        switch bias {
        case .bullish: return .green
        case .bearish: return .red
        case .neutral: return .orange
        }
    }
}

#Preview {
    JournalListView()
        .modelContainer(for: [Trade.self, DailyJournal.self], inMemory: true)
}
