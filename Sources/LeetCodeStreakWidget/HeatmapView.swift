import SwiftUI

private func s(_ v: CGFloat) -> CGFloat { Theme.UI.s(v) }

struct HeatmapView: View {
    let data: HeatmapData

    private static let tooltipFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()

    private func color(for level: Int) -> Color {
        switch level {
        case 1: return Theme.flameL1
        case 2: return Theme.flameL2
        case 3: return Theme.flameL3
        case 4: return Theme.flameL4
        default: return Theme.flameEmpty
        }
    }

    private func tooltip(for cell: HeatmapCell) -> String {
        let day = Self.tooltipFormatter.string(from: cell.date)
        switch cell.count {
        case 0: return "No submissions on \(day)"
        case 1: return "1 submission on \(day)"
        default: return "\(cell.count) submissions on \(day)"
        }
    }

    var body: some View {
        HStack(spacing: s(8)) {
            VStack(alignment: .trailing, spacing: s(4)) {
                Color.clear.frame(height: s(16))
                ForEach(0..<7, id: \.self) { row in
                    Text(dayLabel(row))
                        .font(.system(size: s(10)))
                        .foregroundColor(Theme.textAxis)
                        .frame(height: s(17), alignment: .center)
                }
            }
            .frame(width: s(10))
            .fixedSize(horizontal: true, vertical: false)
            .padding(.trailing, s(7))

            VStack(spacing: 0) {
                // Same column widths as the grid below, labels overflowing to the right.
                HStack(spacing: s(4)) {
                    ForEach(data.monthLabels.indices, id: \.self) { i in
                        Color.clear
                            .frame(width: s(17), height: s(16))
                            .overlay(alignment: .leading) {
                                if let label = data.monthLabels[i] {
                                    Text(label)
                                        .font(.system(size: s(10)))
                                        .foregroundColor(Theme.textAxis)
                                        .fixedSize()
                                }
                            }
                    }
                }
                .frame(height: s(16))

                HStack(spacing: s(4)) {
                    ForEach(data.columns.indices, id: \.self) { col in
                        VStack(spacing: s(4)) {
                            ForEach(0..<7, id: \.self) { row in
                                let cell = data.columns[col][row]
                                RoundedRectangle(cornerRadius: s(3))
                                    .fill(cell.isFuture ? Color.clear : color(for: cell.level))
                                    .frame(width: s(17), height: s(17))
                                    .help(cell.isFuture ? "" : tooltip(for: cell))
                            }
                        }
                    }
                }
            }
        }
    }

    private func dayLabel(_ row: Int) -> String {
        switch row {
        case 0: return "M"
        case 2: return "W"
        case 4: return "F"
        default: return ""
        }
    }
}
