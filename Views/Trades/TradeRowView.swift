import SwiftUI

struct TradeRowView: View {
    let trade: Trade

    var body: some View {
        HStack(spacing: 12) {
            // Direction indicator
            RoundedRectangle(cornerRadius: 4)
                .fill(trade.directionEnum == .long ? Color.green : Color.red)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(trade.displayInstrumentName)
                        .font(.headline)
                    Image(systemName: trade.directionEnum.systemImage)
                        .font(.caption)
                        .foregroundStyle(trade.directionEnum == .long ? .green : .red)
                    Spacer()
                    Text(trade.netPnL.currency)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(trade.netPnL.pnlColor)
                }

                HStack {
                    Text(trade.setup)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(trade.entryTime.shortTime)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Label(String(format: "%.2f pts", trade.points), systemImage: "arrow.up.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .foregroundStyle(.secondary)
                    Label("\(trade.contracts)x", systemImage: "doc.on.doc")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .foregroundStyle(.secondary)
                    Label(trade.durationString, systemImage: "clock")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(trade.grade)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(gradeColor(trade.grade).opacity(0.15))
                        .foregroundStyle(gradeColor(trade.grade))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func gradeColor(_ grade: String) -> Color {
        switch grade {
        case "A+", "A": return .green
        case "B": return .blue
        case "C": return .orange
        case "D", "F": return .red
        default: return .secondary
        }
    }
}
