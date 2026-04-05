import Foundation
import SwiftData

// MARK: - Enums

enum Instrument: String, CaseIterable, Codable, Identifiable {
    var id: String { rawValue }

    case es = "ES"
    case nq = "NQ"
    case ym = "YM"
    case rty = "RTY"
    case cl = "CL"
    case gc = "GC"
    case si = "SI"
    case zb = "ZB"
    case zn = "ZN"
    case ng = "NG"
    case custom = "Custom"

    var fullName: String {
        switch self {
        case .es: return "E-mini S&P 500"
        case .nq: return "E-mini Nasdaq-100"
        case .ym: return "E-mini Dow Jones"
        case .rty: return "E-mini Russell 2000"
        case .cl: return "Crude Oil WTI"
        case .gc: return "Gold"
        case .si: return "Silver"
        case .zb: return "30-Year T-Bond"
        case .zn: return "10-Year T-Note"
        case .ng: return "Natural Gas"
        case .custom: return "Custom"
        }
    }

    var multiplier: Double {
        switch self {
        case .es: return 50.0
        case .nq: return 20.0
        case .ym: return 5.0
        case .rty: return 10.0
        case .cl: return 1000.0
        case .gc: return 100.0
        case .si: return 5000.0
        case .zb: return 1000.0
        case .zn: return 1000.0
        case .ng: return 10000.0
        case .custom: return 1.0
        }
    }

    var tickSize: Double {
        switch self {
        case .es: return 0.25
        case .nq: return 0.25
        case .ym: return 1.0
        case .rty: return 0.1
        case .cl: return 0.01
        case .gc: return 0.10
        case .si: return 0.005
        case .zb: return 0.03125
        case .zn: return 0.015625
        case .ng: return 0.001
        case .custom: return 0.25
        }
    }

    var tickValue: Double {
        multiplier * tickSize
    }
}

enum TradeDirection: String, CaseIterable, Codable {
    case long = "Long"
    case short = "Short"

    var systemImage: String {
        switch self {
        case .long: return "arrow.up.right"
        case .short: return "arrow.down.right"
        }
    }
}

enum TradeSetup: String, CaseIterable, Codable {
    case breakout = "Breakout"
    case breakdown = "Breakdown"
    case vwapBounce = "VWAP Bounce"
    case vwapRejection = "VWAP Rejection"
    case openingRangeBuy = "Opening Range Buy"
    case openingRangeSell = "Opening Range Sell"
    case trendFollowing = "Trend Following"
    case reversal = "Reversal"
    case supportBounce = "Support Bounce"
    case resistanceRejection = "Resistance Rejection"
    case gapFill = "Gap Fill"
    case scalp = "Scalp"
    case newsPlay = "News Play"
    case other = "Other"
}

enum TradeEmotion: String, CaseIterable, Codable {
    case calm = "Calm"
    case confident = "Confident"
    case anxious = "Anxious"
    case fearful = "Fearful"
    case greedy = "Greedy"
    case frustrated = "Frustrated"
    case fomo = "FOMO"
    case neutral = "Neutral"
    case revenge = "Revenge Trading"
}

enum TradeGrade: String, CaseIterable, Codable {
    case aPlus = "A+"
    case a = "A"
    case b = "B"
    case c = "C"
    case d = "D"
    case f = "F"

    var description: String {
        switch self {
        case .aPlus: return "Perfect execution, textbook trade"
        case .a: return "Good trade, followed rules"
        case .b: return "Decent, minor deviations"
        case .c: return "Mediocre, several mistakes"
        case .d: return "Poor execution"
        case .f: return "Broke trading rules"
        }
    }
}

// MARK: - Psychology Tags

enum PsychologyTag: String, CaseIterable {
    // Negative
    case fomo           = "FOMO"
    case revenge        = "Revenge Trading"
    case greed          = "Greed"
    case earlyExit      = "Early Exit"
    case hesitation     = "Hesitation"
    case overTrading    = "Over-trading"
    // Positive
    case disciplined    = "Disciplined"
    case patient        = "Patient"
    case followedPlan   = "Followed Plan"
    case perfectEntry   = "Perfect Entry"

    var isNegative: Bool {
        switch self {
        case .fomo, .revenge, .greed, .earlyExit, .hesitation, .overTrading: return true
        default: return false
        }
    }

    var color: String { isNegative ? "red" : "green" }
}

// MARK: - Trade Model

@Model
final class Trade {
    var id: UUID = UUID()
    var date: Date = Date()
    var instrument: String = Instrument.nq.rawValue
    var customInstrumentName: String = ""
    var customMultiplier: Double = 1.0
    var direction: String = TradeDirection.long.rawValue
    var entryPrice: Double = 0.0
    var exitPrice: Double = 0.0
    var contracts: Int = 1
    var entryTime: Date = Date()
    var exitTime: Date = Date()
    var setup: String = TradeSetup.breakout.rawValue
    var emotion: String = TradeEmotion.calm.rawValue
    var grade: String = TradeGrade.b.rawValue
    var notes: String = ""
    var mistakes: String = ""
    var commission: Double = 0.0
    var stopLoss: Double = 0.0
    var takeProfit: Double = 0.0
    var isManualPnL: Bool = false
    var manualPnL: Double = 0.0
    var tags: [String] = []

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        instrument: String = Instrument.nq.rawValue,
        customInstrumentName: String = "",
        customMultiplier: Double = 1.0,
        direction: String = TradeDirection.long.rawValue,
        entryPrice: Double = 0,
        exitPrice: Double = 0,
        contracts: Int = 1,
        entryTime: Date = Date(),
        exitTime: Date = Date(),
        setup: String = TradeSetup.breakout.rawValue,
        emotion: String = TradeEmotion.calm.rawValue,
        grade: String = TradeGrade.b.rawValue,
        notes: String = "",
        mistakes: String = "",
        commission: Double = 0,
        stopLoss: Double = 0,
        takeProfit: Double = 0,
        isManualPnL: Bool = false,
        manualPnL: Double = 0,
        tags: [String] = []
    ) {
        self.id = id
        self.date = date
        self.instrument = instrument
        self.customInstrumentName = customInstrumentName
        self.customMultiplier = customMultiplier
        self.direction = direction
        self.entryPrice = entryPrice
        self.exitPrice = exitPrice
        self.contracts = contracts
        self.entryTime = entryTime
        self.exitTime = exitTime
        self.setup = setup
        self.emotion = emotion
        self.grade = grade
        self.notes = notes
        self.mistakes = mistakes
        self.commission = commission
        self.stopLoss = stopLoss
        self.takeProfit = takeProfit
        self.isManualPnL = isManualPnL
        self.manualPnL = manualPnL
        self.tags = tags
    }

    // MARK: - Computed Properties

    var instrumentEnum: Instrument {
        Instrument(rawValue: instrument) ?? .nq
    }

    var directionEnum: TradeDirection {
        TradeDirection(rawValue: direction) ?? .long
    }

    var effectiveMultiplier: Double {
        instrumentEnum == .custom ? customMultiplier : instrumentEnum.multiplier
    }

    var displayInstrumentName: String {
        instrumentEnum == .custom ? customInstrumentName : instrument
    }

    var grossPnL: Double {
        if isManualPnL { return manualPnL }
        let priceDiff = exitPrice - entryPrice
        let dir: Double = directionEnum == .long ? 1.0 : -1.0
        return priceDiff * dir * Double(contracts) * effectiveMultiplier
    }

    var netPnL: Double {
        grossPnL - commission
    }

    var isWin: Bool { netPnL > 0 }
    var isBreakeven: Bool { netPnL == 0 }

    var points: Double {
        let dir: Double = directionEnum == .long ? 1.0 : -1.0
        return (exitPrice - entryPrice) * dir
    }

    var riskRewardRatio: Double? {
        guard stopLoss > 0, takeProfit > 0, entryPrice > 0 else { return nil }
        let risk = abs(entryPrice - stopLoss)
        let reward = abs(takeProfit - entryPrice)
        guard risk > 0 else { return nil }
        return reward / risk
    }

    var duration: TimeInterval {
        max(0, exitTime.timeIntervalSince(entryTime))
    }

    var durationString: String {
        let totalSeconds = Int(duration)
        if totalSeconds < 60 { return "\(totalSeconds)s" }
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        if minutes < 60 { return "\(minutes)m \(seconds)s" }
        let hours = minutes / 60
        let mins = minutes % 60
        return "\(hours)h \(mins)m"
    }
}
