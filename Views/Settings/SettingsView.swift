import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var trades: [Trade]
    @Query private var journals: [DailyJournal]

    @AppStorage("defaultInstrument") private var defaultInstrument: String = Instrument.nq.rawValue
    @AppStorage("defaultContracts") private var defaultContracts: Int = 1
    @AppStorage("defaultCommission") private var defaultCommission: Double = 0.0
    @AppStorage("accountBalance") private var accountBalance: Double = 100000
    @AppStorage("accountType") private var accountType: String = "Personal"
    @AppStorage("propFirmMaxDrawdown") private var propFirmMaxDrawdown: Double = 0.0
    @AppStorage("customSetups") private var customSetupsRaw: String = ""
    @AppStorage("dailyLossLimit") private var dailyLossLimit: Double = 0.0

    @State private var showingDeleteAlert = false
    @State private var newSetupName: String = ""

    var customSetups: [String] {
        customSetupsRaw
            .split(separator: "|")
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    func addSetup(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !customSetups.contains(trimmed) else { return }
        let updated = customSetups + [trimmed]
        customSetupsRaw = updated.joined(separator: "|")
    }

    func removeSetups(at offsets: IndexSet) {
        var list = customSetups
        list.remove(atOffsets: offsets)
        customSetupsRaw = list.joined(separator: "|")
    }
    @State private var showingExportSheet = false

    var body: some View {
        NavigationStack {
            Form {
                defaultsSection
                accountSection
                setupsSection
                statsSection
                dataSection
                aboutSection
            }
            .navigationTitle("Settings")
            .alert("Delete All Data", isPresented: $showingDeleteAlert) {
                Button("Delete Everything", role: .destructive) { deleteAllData() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all \(trades.count) trades and \(journals.count) journal entries. This cannot be undone.")
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportView(trades: trades, accountBalance: accountBalance)
            }
        }
    }

    // MARK: - Sections

    private var defaultsSection: some View {
        Section("Trade Defaults") {
            Picker("Default Instrument", selection: $defaultInstrument) {
                ForEach(Instrument.allCases) { inst in
                    Text(inst.rawValue).tag(inst.rawValue)
                }
            }

            Stepper("Default Contracts: \(defaultContracts)", value: $defaultContracts, in: 1...100)

            HStack {
                Text("Default Commission ($)")
                Spacer()
                TextField("0.00", value: $defaultCommission, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
            }
        }
    }

    private var accountSection: some View {
        let stats = StatsCalculator.calculate(from: trades)
        let denominator = accountType == "PropFirm" ? propFirmMaxDrawdown : accountBalance
        let roi: String = {
            guard denominator > 0 else { return "N/A" }
            return ((stats.totalPnL / denominator) * 100).percentage
        }()

        return Section {
            Picker("Account Type", selection: $accountType) {
                Text("Personal").tag("Personal")
                Text("Prop Firm").tag("PropFirm")
            }
            .pickerStyle(.segmented)

            if accountType == "Personal" {
                HStack {
                    Text("Initial Capital ($)")
                    Spacer()
                    TextField("100000", value: $accountBalance, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 120)
                }
            } else {
                HStack {
                    Text("Max Drawdown ($)")
                    Spacer()
                    TextField("0", value: $propFirmMaxDrawdown, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 120)
                }
            }

            HStack {
                Text("Return on Account")
                Spacer()
                Text(roi)
                    .foregroundStyle(denominator > 0 ? stats.totalPnL.pnlColor : .secondary)
            }

            HStack {
                Label("Daily Loss Limit ($)", systemImage: "exclamationmark.shield")
                    .foregroundStyle(.primary)
                Spacer()
                TextField("0", value: $dailyLossLimit, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
            }
        } header: {
            Text("Account")
        } footer: {
            if dailyLossLimit > 0 {
                Text("You will be alerted on the Dashboard when your day's loss reaches -$\(Int(dailyLossLimit)).")
            }
        }
    }

    private var setupsSection: some View {
        Section {
            ForEach(customSetups, id: \.self) { setup in
                Text(setup)
            }
            .onDelete { offsets in
                removeSetups(at: offsets)
            }

            HStack {
                TextField("New setup name…", text: $newSetupName)
                    .autocorrectionDisabled()
                Button {
                    addSetup(newSetupName)
                    newSetupName = ""
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.green)
                }
                .disabled(newSetupName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        } header: {
            Text("My Setups")
        } footer: {
            Text("Swipe left to delete. \"Other\" is always available as a fallback.")
        }
    }

    private var statsSection: some View {
        let stats = StatsCalculator.calculate(from: trades)
        return Section("Overview") {
            HStack {
                Text("Total Trades")
                Spacer()
                Text("\(trades.count)")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Journal Entries")
                Spacer()
                Text("\(journals.count)")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Trading Days")
                Spacer()
                Text("\(stats.tradingDays)")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("All-Time P&L")
                Spacer()
                Text(stats.totalPnL.currency)
                    .fontWeight(.semibold)
                    .foregroundStyle(stats.totalPnL.pnlColor)
            }
        }
    }

    private var dataSection: some View {
        Section("Data") {
            Button {
                showingExportSheet = true
            } label: {
                Label("Export Trades as CSV", systemImage: "square.and.arrow.up")
            }

            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Label("Delete All Data", systemImage: "trash")
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("App")
                Spacer()
                Text("Futures Trading Journal")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Delete

    private func deleteAllData() {
        trades.forEach { modelContext.delete($0) }
        journals.forEach { modelContext.delete($0) }
    }
}

// MARK: - Export View

enum ExportPeriod: String, CaseIterable {
    case week = "This Week"
    case month = "This Month"
    case all = "All Time"

    func filter(_ trades: [Trade]) -> [Trade] {
        let cal = Calendar.current
        switch self {
        case .all: return trades
        case .week:
            guard let start = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))
            else { return trades }
            return trades.filter { $0.date >= start }
        case .month:
            guard let start = cal.date(from: cal.dateComponents([.year, .month], from: Date()))
            else { return trades }
            return trades.filter { $0.date >= start }
        }
    }
}

struct ExportView: View {
    @Environment(\.dismiss) private var dismiss
    let trades: [Trade]
    let accountBalance: Double

    @State private var period: ExportPeriod = .all

    private var filteredTrades: [Trade] {
        period.filter(trades).sorted { $0.entryTime < $1.entryTime }
    }

    private var csvText: String {
        CSVExportService.generate(from: filteredTrades, accountBalance: accountBalance)
    }

    private var csvFile: some Transferable { csvText }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Period", selection: $period) {
                    ForEach(ExportPeriod.allCases, id: \.self) { p in
                        Text(p.rawValue).tag(p)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                Divider()

                // Preview
                ScrollView {
                    Text(csvText)
                        .font(.system(.caption2, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }

                Divider()

                // Summary bar
                HStack {
                    Label("\(filteredTrades.count) trades", systemImage: "doc.text")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    ShareLink(
                        item: csvText,
                        subject: Text("TradingJournal Export"),
                        message: Text("\(period.rawValue) — \(filteredTrades.count) trades")
                    ) {
                        Label("Share / Save", systemImage: "square.and.arrow.up")
                            .fontWeight(.semibold)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.green)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
                .padding()
            }
            .navigationTitle("Export CSV")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Trade.self, DailyJournal.self], inMemory: true)
}
