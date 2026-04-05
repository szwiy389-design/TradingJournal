import Foundation
import SwiftData

enum MarketBias: String, CaseIterable, Codable {
    case bullish = "Bullish"
    case bearish = "Bearish"
    case neutral = "Neutral"

    var systemImage: String {
        switch self {
        case .bullish: return "arrow.up"
        case .bearish: return "arrow.down"
        case .neutral: return "minus"
        }
    }
}

@Model
final class DailyJournal {
    var id: UUID = UUID()
    var date: Date = Date()
    var bias: String = MarketBias.neutral.rawValue
    var keyLevels: String = ""
    var preMarketPlan: String = ""
    var postMarketReview: String = ""
    var lessonsLearned: String = ""
    var mood: Int = 3  // 1–5 scale

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        bias: String = MarketBias.neutral.rawValue,
        keyLevels: String = "",
        preMarketPlan: String = "",
        postMarketReview: String = "",
        lessonsLearned: String = "",
        mood: Int = 3
    ) {
        self.id = id
        self.date = date
        self.bias = bias
        self.keyLevels = keyLevels
        self.preMarketPlan = preMarketPlan
        self.postMarketReview = postMarketReview
        self.lessonsLearned = lessonsLearned
        self.mood = mood
    }

    var biasEnum: MarketBias {
        MarketBias(rawValue: bias) ?? .neutral
    }

    var moodEmoji: String {
        switch mood {
        case 1: return "Terrible"
        case 2: return "Poor"
        case 3: return "Okay"
        case 4: return "Good"
        case 5: return "Great"
        default: return "Okay"
        }
    }

    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
}
