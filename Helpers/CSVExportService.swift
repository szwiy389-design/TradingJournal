import Foundation

enum CSVExportService {

    static let header = "Date,Entry Time,Exit Time,Instrument,Setup,Side,Contracts,Entry Price,Exit Price,Points,Gross P&L,Commission,Net P&L,ROI (%),Emotion,Grade,Tags,Notes,Mistakes"

    static func generate(from trades: [Trade], accountBalance: Double) -> String {
        var lines = [header]
        for trade in trades {
            lines.append(row(for: trade, accountBalance: accountBalance))
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Private

    private static func row(for trade: Trade, accountBalance: Double) -> String {
        let roi: String = {
            guard accountBalance > 0 else { return "0.00" }
            return String(format: "%.4f", (trade.netPnL / accountBalance) * 100)
        }()

        let fields: [String] = [
            esc(trade.date.shortDate),
            esc(trade.entryTime.shortTime),
            esc(trade.exitTime.shortTime),
            esc(trade.displayInstrumentName),
            esc(trade.setup),
            esc(trade.direction),
            String(trade.contracts),
            String(format: "%.4g", trade.entryPrice),
            String(format: "%.4g", trade.exitPrice),
            String(format: "%.2f", trade.points),
            String(format: "%.2f", trade.grossPnL),
            String(format: "%.2f", trade.commission),
            String(format: "%.2f", trade.netPnL),
            roi,
            esc(trade.emotion),
            esc(trade.grade),
            esc(trade.tags.joined(separator: "; ")),
            esc(trade.notes),
            esc(trade.mistakes)
        ]
        return fields.joined(separator: ",")
    }

    /// Wraps a string in quotes and escapes internal quotes per RFC 4180.
    private static func esc(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}
