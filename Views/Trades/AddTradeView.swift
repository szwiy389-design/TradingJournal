import SwiftUI
import SwiftData

struct AddTradeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var existingTrade: Trade? = nil

    // Basic fields
    @State private var instrument: Instrument = .nq
    @State private var customName: String = ""
    @State private var customMultiplier: Double = 1.0
    @State private var direction: TradeDirection = .long
    @State private var contracts: Int = 1
    @State private var entryPrice: String = ""
    @State private var exitPrice: String = ""
    @State private var entryTime: Date = Date()
    @State private var exitTime: Date = Date().addingTimeInterval(300)

    // Analysis fields
    @AppStorage("customSetups") private var customSetupsRaw: String = ""
    @State private var setupName: String = "Other"
    @State private var emotion: TradeEmotion = .calm
    @State private var grade: TradeGrade = .b
    @State private var notes: String = ""
    @State private var mistakes: String = ""

    // Psychology tags
    @State private var selectedTags: [String] = []

    // Optional fields
    @State private var stopLoss: String = ""
    @State private var takeProfit: String = ""
    @State private var commission: String = ""
    @State private var isManualPnL: Bool = false
    @State private var manualPnL: String = ""

    var isEditing: Bool { existingTrade != nil }

    var availableSetups: [String] {
        let custom = customSetupsRaw
            .split(separator: "|")
            .map(String.init)
            .filter { !$0.isEmpty }
        return custom + (custom.contains("Other") ? [] : ["Other"])
    }

    var calculatedPnL: Double? {
        guard !isManualPnL,
              let entry = Double(entryPrice),
              let exit = Double(exitPrice),
              entry > 0 else { return nil }
        let diff = exit - entry
        let dir: Double = direction == .long ? 1.0 : -1.0
        let multiplier = instrument == .custom ? customMultiplier : instrument.multiplier
        let comm = Double(commission) ?? 0
        return (diff * dir * Double(contracts) * multiplier) - comm
    }

    var body: some View {
        NavigationStack {
            Form {
                instrumentSection
                priceSection
                timingSection
                analysisSection
                tagsSection
                optionalSection
            }
            .navigationTitle(isEditing ? "Edit Trade" : "New Trade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Update" : "Save") { saveTrade() }
                        .fontWeight(.semibold)
                        .disabled(!isValid)
                }
            }
            .onAppear { loadExistingTrade() }
        }
    }

    // MARK: - Sections

    private var instrumentSection: some View {
        Section("Instrument & Direction") {
            Picker("Instrument", selection: $instrument) {
                ForEach(Instrument.allCases) { inst in
                    Text("\(inst.rawValue) – \(inst.fullName)").tag(inst)
                }
            }

            if instrument == .custom {
                TextField("Instrument name", text: $customName)
                HStack {
                    Text("Multiplier")
                    Spacer()
                    TextField("e.g. 50", value: $customMultiplier, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }

            Picker("Direction", selection: $direction) {
                ForEach(TradeDirection.allCases, id: \.self) { dir in
                    Label(dir.rawValue, systemImage: dir.systemImage).tag(dir)
                }
            }
            .pickerStyle(.segmented)

            Stepper("Contracts: \(contracts)", value: $contracts, in: 1...100)
        }
    }

    private var priceSection: some View {
        Section {
            HStack {
                Text("Entry Price")
                Spacer()
                TextField("0.00", text: $entryPrice)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
            }
            HStack {
                Text("Exit Price")
                Spacer()
                TextField("0.00", text: $exitPrice)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
            }

            if let pnl = calculatedPnL {
                HStack {
                    Text("Estimated P&L")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(pnl.currency)
                        .fontWeight(.semibold)
                        .foregroundStyle(pnl.pnlColor)
                }
            }

            Toggle("Override P&L manually", isOn: $isManualPnL)
            if isManualPnL {
                HStack {
                    Text("Manual P&L")
                    Spacer()
                    TextField("0.00", text: $manualPnL)
                        .keyboardType(.numbersAndPunctuation)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 120)
                }
            }
        } header: {
            Text("Prices")
        } footer: {
            if instrument != .custom {
                Text("Multiplier: \(instrument.rawValue) = $\(Int(instrument.multiplier)) per point")
                    .font(.caption)
            }
        }
    }

    private var timingSection: some View {
        Section("Timing") {
            DatePicker("Entry Time", selection: $entryTime)
            DatePicker("Exit Time", selection: $exitTime)
        }
    }

    private var analysisSection: some View {
        Section("Analysis") {
            Picker("Setup", selection: $setupName) {
                ForEach(availableSetups, id: \.self) { s in
                    Text(s).tag(s)
                }
            }

            Picker("Emotion", selection: $emotion) {
                ForEach(TradeEmotion.allCases, id: \.self) { e in
                    Text(e.rawValue).tag(e)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Grade")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Picker("Grade", selection: $grade) {
                    ForEach(TradeGrade.allCases, id: \.self) { g in
                        Text(g.rawValue).tag(g)
                    }
                }
                .pickerStyle(.segmented)
                Text(grade.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 4) {
                Text("Notes")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextEditor(text: $notes)
                    .frame(minHeight: 80)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Mistakes / Lessons")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextEditor(text: $mistakes)
                    .frame(minHeight: 60)
            }
        }
    }

    private var tagsSection: some View {
        Section("Psychology Tags") {
            TagSelectorView(selectedTags: $selectedTags)
                .padding(.vertical, 4)
        }
    }

    private var optionalSection: some View {
        Section("Risk Management (Optional)") {
            HStack {
                Text("Stop Loss")
                Spacer()
                TextField("0.00", text: $stopLoss)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
            }
            HStack {
                Text("Take Profit")
                Spacer()
                TextField("0.00", text: $takeProfit)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
            }
            HStack {
                Text("Commission")
                Spacer()
                TextField("0.00", text: $commission)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
            }
        }
    }

    // MARK: - Validation

    var isValid: Bool {
        if isManualPnL {
            return Double(manualPnL) != nil
        }
        guard let entry = Double(entryPrice), let exit = Double(exitPrice) else { return false }
        return entry > 0 && exit > 0
    }

    // MARK: - Save

    private func saveTrade() {
        let trade = existingTrade ?? Trade()

        trade.instrument = instrument.rawValue
        trade.customInstrumentName = customName
        trade.customMultiplier = customMultiplier
        trade.direction = direction.rawValue
        trade.contracts = contracts
        trade.entryPrice = Double(entryPrice) ?? 0
        trade.exitPrice = Double(exitPrice) ?? 0
        trade.entryTime = entryTime
        trade.exitTime = exitTime
        trade.date = Calendar.current.startOfDay(for: entryTime)
        trade.setup = setupName
        trade.emotion = emotion.rawValue
        trade.grade = grade.rawValue
        trade.notes = notes
        trade.mistakes = mistakes
        trade.stopLoss = Double(stopLoss) ?? 0
        trade.takeProfit = Double(takeProfit) ?? 0
        trade.commission = Double(commission) ?? 0
        trade.isManualPnL = isManualPnL
        trade.manualPnL = Double(manualPnL) ?? 0
        trade.tags = selectedTags

        if existingTrade == nil {
            modelContext.insert(trade)
        }

        dismiss()
    }

    // MARK: - Load existing

    private func loadExistingTrade() {
        guard let trade = existingTrade else { return }
        instrument = trade.instrumentEnum
        customName = trade.customInstrumentName
        customMultiplier = trade.customMultiplier
        direction = trade.directionEnum
        contracts = trade.contracts
        entryPrice = String(trade.entryPrice)
        exitPrice = String(trade.exitPrice)
        entryTime = trade.entryTime
        exitTime = trade.exitTime
        setupName = trade.setup
        emotion = TradeEmotion(rawValue: trade.emotion) ?? .calm
        grade = TradeGrade(rawValue: trade.grade) ?? .b
        notes = trade.notes
        mistakes = trade.mistakes
        stopLoss = trade.stopLoss > 0 ? String(trade.stopLoss) : ""
        takeProfit = trade.takeProfit > 0 ? String(trade.takeProfit) : ""
        commission = trade.commission > 0 ? String(trade.commission) : ""
        isManualPnL = trade.isManualPnL
        manualPnL = trade.isManualPnL ? String(trade.manualPnL) : ""
        selectedTags = trade.tags
    }
}

#Preview {
    AddTradeView()
        .modelContainer(for: [Trade.self, DailyJournal.self], inMemory: true)
}
