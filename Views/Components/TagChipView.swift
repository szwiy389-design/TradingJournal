import SwiftUI

// MARK: - Single chip

struct TagChip: View {
    let tag: PsychologyTag
    let isSelected: Bool
    let onTap: () -> Void

    private var activeColor: Color {
        tag.isNegative ? .red : .green
    }

    var body: some View {
        Button(action: onTap) {
            Text(tag.rawValue)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isSelected ? activeColor.opacity(0.2) : Color(.tertiarySystemFill))
                .foregroundStyle(isSelected ? activeColor : .secondary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? activeColor.opacity(0.6) : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Full tag selector

struct TagSelectorView: View {
    @Binding var selectedTags: [String]

    private let negativeTags = PsychologyTag.allCases.filter { $0.isNegative }
    private let positiveTags = PsychologyTag.allCases.filter { !$0.isNegative }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            tagGroup(title: "Negative", tags: negativeTags)
            tagGroup(title: "Positive", tags: positiveTags)
        }
    }

    private func tagGroup(title: String, tags: [PsychologyTag]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            FlowLayout(spacing: 6) {
                ForEach(tags, id: \.rawValue) { tag in
                    TagChip(
                        tag: tag,
                        isSelected: selectedTags.contains(tag.rawValue)
                    ) {
                        if selectedTags.contains(tag.rawValue) {
                            selectedTags.removeAll { $0 == tag.rawValue }
                        } else {
                            selectedTags.append(tag.rawValue)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Flow Layout (wrapping HStack)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var x: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                height += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        height += rowHeight
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
