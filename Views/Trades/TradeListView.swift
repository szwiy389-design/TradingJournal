import SwiftUI
import SwiftData

struct TradeListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Trade.date, order: .reverse) private var trades: [Trade]
    @State private var showingAddTrade = false
    @State private var searchText = ""
    @State private var selectedInstrument: String = "All"

    var availableInstruments: [String] {
        let instruments = Set(trades.map { $0.displayInstrumentName })
        return ["All"] + instruments.sorted()
    }

    var filteredTrades: [Trade] {
        trades.filter { trade in
            let matchesSearch = searchText.isEmpty ||
                trade.displayInstrumentName.localizedCaseInsensitiveContains(searchText) ||
                trade.setup.localizedCaseInsensitiveContains(searchText) ||
                trade.notes.localizedCaseInsensitiveContains(searchText)
            let matchesInstrument = selectedInstrument == "All" || trade.displayInstrumentName == selectedInstrument
            return matchesSearch && matchesInstrument
        }
    }

    var groupedTrades: [(String, [Trade])] {
        let grouped = Dictionary(grouping: filteredTrades) { $0.date.dayKey }
        return grouped.sorted { $0.key > $1.key }
            .map { key, trades in (key, trades.sorted { $0.entryTime > $1.entryTime }) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if trades.isEmpty {
                    emptyState
                } else {
                    tradesList
                }
            }
            .navigationTitle("Trades")
            .searchable(text: $searchText, prompt: "Search trades")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddTrade = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingAddTrade) {
                AddTradeView()
            }
        }
    }

    // MARK: - Trades List

    private var tradesList: some View {
        List {
            // Instrument filter pills
            if availableInstruments.count > 2 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(availableInstruments, id: \.self) { instrument in
                            Button {
                                selectedInstrument = instrument
                            } label: {
                                Text(instrument)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedInstrument == instrument ? Color.accentColor : Color(.tertiarySystemBackground))
                                    .foregroundStyle(selectedInstrument == instrument ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            ForEach(groupedTrades, id: \.0) { dayKey, dayTrades in
                Section {
                    ForEach(dayTrades) { trade in
                        NavigationLink(destination: TradeDetailView(trade: trade)) {
                            TradeRowView(trade: trade)
                        }
                    }
                    .onDelete { offsets in
                        deleteTrades(dayTrades, at: offsets)
                    }
                } header: {
                    DaySectionHeader(trades: dayTrades, dayKey: dayKey)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis.circle")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("No Trades Yet")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Tap + to log your first futures trade")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Log First Trade") {
                showingAddTrade = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    // MARK: - Delete

    private func deleteTrades(_ dayTrades: [Trade], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(dayTrades[index])
        }
    }
}

// MARK: - Day Section Header

struct DaySectionHeader: View {
    let trades: [Trade]
    let dayKey: String

    var dayPnL: Double { trades.reduce(0) { $0 + $1.netPnL } }

    var dayDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dayKey) else { return dayKey }
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        let display = DateFormatter()
        display.dateStyle = .medium
        return display.string(from: date)
    }

    var body: some View {
        HStack {
            Text(dayDate)
                .fontWeight(.semibold)
            Spacer()
            Text(dayPnL.currency)
                .fontWeight(.semibold)
                .foregroundStyle(dayPnL.pnlColor)
        }
    }
}

#Preview {
    TradeListView()
        .modelContainer(for: [Trade.self, DailyJournal.self], inMemory: true)
}
