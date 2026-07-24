import SwiftUI
import AppKit

struct PixelFlameView: View {
    var cellSize: CGFloat = 2.6
    var gap: CGFloat = 1

    var body: some View {
        let rows = Theme.flameBitmap
        VStack(spacing: gap) {
            ForEach(0..<rows.count, id: \.self) { r in
                HStack(spacing: gap) {
                    ForEach(0..<rows[r].count, id: \.self) { c in
                        RoundedRectangle(cornerRadius: cellSize * 0.3)
                            .fill(Theme.flamePixelColor(rows[r][c]))
                            .frame(width: cellSize, height: cellSize)
                    }
                }
            }
        }
    }
}

struct HeaderIconTile: View {
    var body: some View {
        RoundedRectangle(cornerRadius: Theme.UI.s(9))
            .fill(Theme.iconTileGradient)
            .frame(width: Theme.UI.s(32), height: Theme.UI.s(32))
            .shadow(color: .black.opacity(0.35), radius: 1.5, x: 0, y: 1)
            .overlay(PixelFlameView(cellSize: Theme.UI.s(2.6), gap: Theme.UI.s(1)))
    }
}

/// Renders the pixel-flame bitmap into an NSImage for use as the menu bar status item icon.
enum FlameIconRenderer {
    static func makeStatusIcon(cellSize: CGFloat = 2.5, grayscale: Bool = false) -> NSImage {
        let rows = Theme.flameBitmap
        let cols = rows[0].count
        let width = CGFloat(cols) * cellSize
        let height = CGFloat(rows.count) * cellSize
        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()
        for (r, row) in rows.enumerated() {
            for (c, value) in row.enumerated() {
                guard value != 0 else { continue }
                let nsColor: NSColor
                if grayscale {
                    // Dimmed monochrome flame for the "not solved today" state.
                    switch value {
                    case 1: nsColor = NSColor(white: 0.62, alpha: 1)
                    case 2: nsColor = NSColor(white: 0.50, alpha: 1)
                    default: nsColor = NSColor(white: 0.38, alpha: 1)
                    }
                } else {
                    switch value {
                    case 1: nsColor = NSColor(red: 0xFF / 255, green: 0xD2 / 255, blue: 0x4A / 255, alpha: 1)
                    case 2: nsColor = NSColor(red: 0xFF / 255, green: 0xA1 / 255, blue: 0x16 / 255, alpha: 1)
                    default: nsColor = NSColor(red: 0xFF / 255, green: 0x5D / 255, blue: 0x3B / 255, alpha: 1)
                    }
                }
                let rect = NSRect(
                    x: CGFloat(c) * cellSize,
                    y: CGFloat(rows.count - 1 - r) * cellSize,
                    width: cellSize,
                    height: cellSize
                )
                nsColor.setFill()
                NSBezierPath(roundedRect: rect, xRadius: cellSize * 0.3, yRadius: cellSize * 0.3).fill()
            }
        }
        image.unlockFocus()
        image.isTemplate = false
        return image
    }
}
