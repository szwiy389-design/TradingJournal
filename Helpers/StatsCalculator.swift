import Foundation
import SwiftUI

struct TradeStats {
    let totalPnL: Double
    let totalTrades: Int
    let winningTrades: Int
    let losingTrades: Int
    let breakevenTrades: Int
    let winRate: Double
    let avgWin: Double
    let avgLoss: Double
    let profitFactor: Double
    let largestWin: Double
    let largestLoss: Double
    let avgDurationSeconds: Double
    let tradingDays: Int
    let avgDailyPnL: Double
    let maxDrawdown: Double
    let expectancy: Double

    var lossRate: Double { 1.0 - winRate }

    var riskRewardRatio: Double {
        guard avgLoss != 0 else { return 0 }
        return avgWin / abs(avgLoss)
    }
}

struct DailyPnL: Identifiable {
    let id = UUID()
    let date: Date
    let pnl: Double
    let cumulative: Double
}

struct SetupStats: Identifiable {
    let id = UUID()
    let setup: String
    let count: Int
    let winRate: Double
    let totalPnL: Double
    let avgPnL: Double
}

struct HourlyPnL: Identifiable {
    let id = UUID()
    let hour: Int
    let pnl: Double
    var label: String { String(format: "%02d:00", hour) }
}

struct InstrumentStats: Identifiable {
    let id = UUID()
    let instrument: String
    let count: Int
    let totalPnL: Double
    let winRate: Double
}

enum StatsCalculator {

    static func calculate(from trades: [Trade]) -> TradeStats {
        guard !trades.isEmpty else {
            return TradeStats(
                totalPnL: 0, totalTrades: 0, winningTrades: 0,
                losingTrades: 0, breakevenTrades: 0, winRate: 0,
                avgWin: 0, avgLoss: 0, profitFactor: 0,
                largestWin: 0, largestLoss: 0, avgDurationSeconds: 0,
                tradingDays: 0, avgDailyPnL: 0, maxDrawdown: 0, expectancy: 0
            )
        }

        let totalPnL = trades.reduce(0) { $0 + $1.netPnL }
        let wins = trades.filter { $0.netPnL > 0 }
        let losses = trades.filter { $0.netPnL < 0 }
        let breakevens = trades.filter { $0.netPnL == 0 }

        let winRate = Double(wins.count) / Double(trades.count)
        let avgWin = wins.isEmpty ? 0 : wins.reduce(0) { $0 + $1.netPnL } / Double(wins.count)
        let avgLoss = losses.isEmpty ? 0 : losses.reduce(0) { $0 + $1.netPnL } / Double(losses.count)
        let largestWin = wins.map { $0.netPnL }.max() ?? 0
        let largestLoss = losses.map { $0.netPnL }.min() ?? 0

        let grossProfit = wins.reduce(0) { $0 + $1.netPnL }
        let grossLoss = abs(losses.reduce(0) { $0 + $1.netPnL })
        let profitFactor = grossLoss > 0 ? grossProfit / grossLoss : (grossProfit > 0 ? .infinity : 0)

        let avgDuration = trades.isEmpty ? 0 : trades.reduce(0) { $0 + $1.duration } / Double(trades.count)

        let dayGroups = Dictionary(grouping: trades) { $0.date.dayKey }
        let tradingDays = dayGroups.count
        let avgDailyPnL = tradingDays > 0 ? totalPnL / Double(tradingDays) : 0

        let maxDrawdown = calculateMaxDrawdown(trades: trades)
        let expectancy = (winRate * avgWin) + ((1 - winRate) * avgLoss)

        return TradeStats(
            totalPnL: totalPnL,
            totalTrades: trades.count,
            winningTrades: wins.count,
            losingTrades: losses.count,
            breakevenTrades: breakevens.count,
            winRate: winRate,
            avgWin: avgWin,
            avgLoss: avgLoss,
            profitFactor: profitFactor,
            largestWin: largestWin,
            largestLoss: largestLoss,
            avgDurationSeconds: avgDuration,
            tradingDays: tradingDays,
            avgDailyPnL: avgDailyPnL,
            maxDrawdown: maxDrawdown,
            expectancy: expectancy
        )
    }

    static func dailyPnL(from trades: [Trade]) -> [DailyPnL] {
        let sorted = trades.sorted { $0.date < $1.date }
        let grouped = Dictionary(grouping: sorted) { $0.date.dayKey }
        let sortedKeys = grouped.keys.sorted()

        var cumulative = 0.0
        return sortedKeys.compactMap { key -> DailyPnL? in
            guard let dayTrades = grouped[key], let first = dayTrades.first else { return nil }
            let dayPnL = dayTrades.reduce(0) { $0 + $1.netPnL }
            cumulative += dayPnL
            return DailyPnL(date: first.date, pnl: dayPnL, cumulative: cumulative)
        }
    }

    static func equityCurve(from trades: [Trade]) -> [(date: Date, value: Double)] {
        let sorted = trades.sorted { $0.exitTime < $1.exitTime }
        var cumulative = 0.0
        return sorted.map { trade in
            cumulative += trade.netPnL
            return (date: trade.exitTime, value: cumulative)
        }
    }

    static func setupStats(from trades: [Trade]) -> [SetupStats] {
        let grouped = Dictionary(grouping: trades) { $0.setup }
        return grouped.map { setup, setTrades in
            let wins = setTrades.filter { $0.netPnL > 0 }
            let total = setTrades.reduce(0) { $0 + $1.netPnL }
            return SetupStats(
                setup: setup,
                count: setTrades.count,
                winRate: Double(wins.count) / Double(setTrades.count),
                totalPnL: total,
                avgPnL: total / Double(setTrades.count)
            )
        }
        .sorted { $0.totalPnL > $1.totalPnL }
    }

    static func hourlyPnL(from trades: [Trade]) -> [HourlyPnL] {
        let calendar = Calendar.current
        var pnlByHour = [Int: Double]()
        for trade in trades {
            let hour = calendar.component(.hour, from: trade.entryTime)
            pnlByHour[hour, default: 0] += trade.netPnL
        }
        return pnlByHour.map { HourlyPnL(hour: $0.key, pnl: $0.value) }
            .sorted { $0.hour < $1.hour }
    }

    static func instrumentStats(from trades: [Trade]) -> [InstrumentStats] {
        let grouped = Dictionary(grouping: trades) { $0.displayInstrumentName }
        return grouped.map { instrument, instTrades in
            let wins = instTrades.filter { $0.netPnL > 0 }
            let total = instTrades.reduce(0) { $0 + $1.netPnL }
            return InstrumentStats(
                instrument: instrument,
                count: instTrades.count,
                totalPnL: total,
                winRate: Double(wins.count) / Double(instTrades.count)
            )
        }
        .sorted { $0.totalPnL > $1.totalPnL }
    }

    // MARK: - Private

    private static func calculateMaxDrawdown(trades: [Trade]) -> Double {
        let sorted = trades.sorted { $0.exitTime < $1.exitTime }
        var peak = 0.0
        var cumulative = 0.0
        var maxDrawdown = 0.0

        for trade in sorted {
            cumulative += trade.netPnL
            if cumulative > peak { peak = cumulative }
            let drawdown = peak - cumulative
            if drawdown > maxDrawdown { maxDrawdown = drawdown }
        }

        return maxDrawdown
    }
}
