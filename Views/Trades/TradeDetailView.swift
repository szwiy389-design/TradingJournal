import SwiftUI
import SwiftData

struct TradeDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let trade: Trade
    @State private var showingEdit = false
    @State private var showingDeleteAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // P&L Hero
                pnlHero

                // Trade Details
                detailsCard

                // Analysis Card
                analysisCard

                // Risk Management (if set)
                if trade.stopLoss > 0 || trade.takeProfit > 0 {
                    riskCard
                }

                // Notes
                if !trade.notes.isEmpty {
                    notesCard(title: "Notes", text: trade.notes, icon: "note.text")
                }

                // Mistakes
                if !trade.mistakes.isEmpty {
                    notesCard(title: "Mistakes / Lessons", text: trade.mistakes, icon: "exclamationmark.circle")
                }
            }
            .padding()
        }
        .navigationTitle("\(trade.displayInstrumentName) Trade")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Edit Trade") { showingEdit = true }
                    Button("Delete Trade", role: .destructive) { showingDeleteAlert = true }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            AddTradeView(existingTrade: trade)
        }
        .alert("Delete Trade", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                modelContext.delete(trade)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
    }

    // MARK: - P&L Hero

    private var pnlHero: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Label(trade.directionEnum.rawValue, systemImage: trade.directionEnum.systemImage)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(trade.directionEnum == .long ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                    .foregroundStyle(trade.directionEnum == .long ? .green : .red)
                    .clipShape(Capsule())

                Text(trade.displayInstrumentName)
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Text(trade.grade)
                    .font(.title3)
                    .fontWeight(.bold)
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Circle())
            }

            Text(trade.netPnL.currency)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(trade.netPnL.pnlColor)

            HStack(spacing: 16) {
                VStack {
                    Text(String(format: "%+.2f pts", trade.points))
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Points")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Divider().frame(height: 30)
                VStack {
                    Text("\(trade.contracts)x")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Contracts")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Divider().frame(height: 30)
                VStack {
                    Text(trade.durationString)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Duration")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if trade.commission > 0 {
                    Divider().frame(height: 30)
                    VStack {
                        Text(trade.commission.currency)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Commissions")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Details Card

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Trade Details")
                .font(.headline)
                .padding()

            Divider()

            Group {
                DetailRow(label: "Date", value: trade.date.shortDate)
                Divider()
                DetailRow(label: "Entry Time", value: trade.entryTime.shortTime)
                Divider()
                DetailRow(label: "Exit Time", value: trade.exitTime.shortTime)
                Divider()
                DetailRow(label: "Entry Price", value: String(format: "%.4g", trade.entryPrice))
                Divider()
                DetailRow(label: "Exit Price", value: String(format: "%.4g", trade.exitPrice))
                Divider()
                DetailRow(label: "Gross P&L", value: trade.grossPnL.currency, valueColor: trade.grossPnL.pnlColor)
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Analysis Card

    private var analysisCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Analysis")
                .font(.headline)
                .padding()

            Divider()

            Group {
                DetailRow(label: "Setup", value: trade.setup)
                Divider()
                DetailRow(label: "Emotion", value: trade.emotion)
                Divider()
                DetailRow(label: "Grade", value: "\(trade.grade) – \(TradeGrade(rawValue: trade.grade)?.description ?? "")")
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Risk Card

    private var riskCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Risk Management")
                .font(.headline)
                .padding()

            Divider()

            if trade.stopLoss > 0 {
                DetailRow(label: "Stop Loss", value: String(format: "%.4g", trade.stopLoss))
                Divider()
            }
            if trade.takeProfit > 0 {
                DetailRow(label: "Take Profit", value: String(format: "%.4g", trade.takeProfit))
                Divider()
            }
            if let rr = trade.riskRewardRatio {
                DetailRow(label: "R/R Ratio", value: String(format: "1:%.2f", rr))
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Notes Card

    private func notesCard(title: String, text: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.headline)
            Text(text)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}

#Preview {
    NavigationStack {
        TradeDetailView(trade: {
            let t = Trade()
            t.instrument = "NQ"
            t.direction = "Long"
            t.entryPrice = 19850
            t.exitPrice = 19900
            t.contracts = 2
            t.setup = "VWAP Bounce"
            t.grade = "A"
            t.notes = "Clean VWAP bounce with increasing volume"
            return t
        }())
    }
    .modelContainer(for: [Trade.self, DailyJournal.self], inMemory: true)
}
