import Foundation

enum AtlasError: LocalizedError {
    case noApiKey
    case networkError(String)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .noApiKey:       return "No API key set. Add your Anthropic key in Settings."
        case .networkError(let msg): return msg
        case .decodingError:  return "Could not read API response."
        }
    }
}

struct AtlasService {

    // MARK: - Build prompt

    static func buildPrompt(trades: [Trade], journals: [DailyJournal], userMessage: String, dailyLossLimit: Double = 0) -> String {
        let stats = StatsCalculator.calculate(from: trades)

        // Tag frequency analysis
        var tagCounts: [String: (count: Int, pnl: Double)] = [:]
        for trade in trades {
            for tag in trade.tags {
                var entry = tagCounts[tag] ?? (0, 0)
                entry.count += 1
                entry.pnl += trade.netPnL
                tagCounts[tag] = entry
            }
        }

        let tagSummary = tagCounts
            .sorted { $0.value.count > $1.value.count }
            .map { tag, data in
                let avg = data.pnl / Double(data.count)
                return "• \(tag): \(data.count) trades, avg P&L \(String(format: "%.0f", avg))$"
            }
            .joined(separator: "\n")

        // Recent trades (last 20)
        let recentTrades = trades.sorted { $0.entryTime > $1.entryTime }.prefix(20)
        let tradesSummary = recentTrades.map { t in
            let tagsStr = t.tags.isEmpty ? "none" : t.tags.joined(separator: ", ")
            return "[\(t.date.shortDate)] \(t.displayInstrumentName) \(t.direction) | P&L: \(String(format: "%.0f", t.netPnL))$ | Emotion: \(t.emotion) | Tags: \(tagsStr) | Grade: \(t.grade)"
        }.joined(separator: "\n")

        // Daily loss limit check
        let todayStart = Calendar.current.startOfDay(for: Date())
        let todayPnL = trades.filter { $0.date >= todayStart }.reduce(0) { $0 + $1.netPnL }
        let limitBreached = dailyLossLimit > 0 && todayPnL <= -dailyLossLimit
        let limitStatus: String = {
            guard dailyLossLimit > 0 else { return "No daily loss limit set." }
            if limitBreached {
                return "⚠️ DAILY LOSS LIMIT BREACHED. Today's P&L: \(String(format: "%.0f", todayPnL))$ (limit: -\(String(format: "%.0f", dailyLossLimit))$). The trader should NOT be trading right now."
            }
            return "Today's P&L: \(String(format: "%.0f", todayPnL))$ | Limit: -\(String(format: "%.0f", dailyLossLimit))$ | Remaining cushion: \(String(format: "%.0f", dailyLossLimit + todayPnL))$"
        }()

        // Recent journal mood
        let recentJournals = journals.sorted { $0.date > $1.date }.prefix(5)
        let journalSummary = recentJournals.map { j in
            "[\(j.date.shortDate)] Mood: \(j.mood)/5 | Bias: \(j.bias)"
        }.joined(separator: "\n")

        return """
        You are Atlas, an elite AI trading coach specializing in trading psychology and performance analysis. \
        You are direct, insightful, and data-driven. You identify patterns that the trader might not see.

        === TRADER PERFORMANCE SUMMARY ===
        Total Trades: \(stats.totalTrades)
        Win Rate: \(String(format: "%.1f", stats.winRate * 100))%
        Total P&L: \(String(format: "%.0f", stats.totalPnL))$
        Profit Factor: \(String(format: "%.2f", stats.profitFactor))
        Avg Win: \(String(format: "%.0f", stats.avgWin))$ | Avg Loss: \(String(format: "%.0f", stats.avgLoss))$
        Max Drawdown: \(String(format: "%.0f", stats.maxDrawdown))$
        Expectancy: \(String(format: "%.0f", stats.expectancy))$ per trade

        === PSYCHOLOGY TAG ANALYSIS ===
        \(tagSummary.isEmpty ? "No tags logged yet." : tagSummary)

        === RECENT TRADES (last 20) ===
        \(tradesSummary.isEmpty ? "No trades yet." : tradesSummary)

        === RECENT JOURNAL (last 5 days) ===
        \(journalSummary.isEmpty ? "No journal entries yet." : journalSummary)

        === DAILY LOSS LIMIT STATUS ===
        \(limitStatus)

        === TRADER QUESTION ===
        \(userMessage)

        Respond concisely and directly. Focus on patterns in the data. \
        If you spot a psychological pattern (e.g. FOMO trades losing money), call it out explicitly. \
        If the daily loss limit is breached, acknowledge it first with empathy, then offer a specific \
        cool-down exercise (e.g. box breathing, journaling prompt, or a walk). Be firm but supportive. \
        Keep responses under 300 words unless a detailed breakdown is needed.
        """
    }

    // MARK: - Call Claude API

    static func ask(
        prompt: String,
        apiKey: String
    ) async throws -> String {
        guard !apiKey.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw AtlasError.noApiKey
        }

        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 1024,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AtlasError.networkError(msg)
        }

        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let content = (json["content"] as? [[String: Any]])?.first,
            let text = content["text"] as? String
        else {
            throw AtlasError.decodingError
        }

        return text
    }
}
