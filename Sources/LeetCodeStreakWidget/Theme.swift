import SwiftUI

enum Theme {
    /// Global UI scale for the popover. 1.0 = original size; lower shrinks
    /// every dimension (fonts, padding, heatmap cells) uniformly.
    enum UI {
        static let scale: CGFloat = 0.8
        /// Fonts scale less aggressively than layout so text stays readable
        /// in the compact popover.
        static let fontScale: CGFloat = 0.9
        /// Scales a layout dimension (padding, frames, cells) by the global factor.
        static func s(_ value: CGFloat) -> CGFloat { value * scale }
        /// Scales a font size by the (larger) font factor.
        static func f(_ value: CGFloat) -> CGFloat { value * fontScale }
    }

    static let textPrimary = Color.white
    static let textMenu = Color(hex: 0xE6E8EC)
    static let textSecondary = Color(hex: 0x9AA1AD)
    static let textTertiary = Color(hex: 0x8A91A0)
    static let textAxis = Color(hex: 0x7D8492)
    static let difficultyLabel = Color(hex: 0xC9CCD2)

    static let flameL1 = Color(hex: 0xFFD24A)
    static let flameL2 = Color(hex: 0xFFA116)
    static let flameL3 = Color(hex: 0xFF6A2C)
    static let flameL4 = Color(hex: 0xEF3E2A)
    static let flameEmpty = Color.white.opacity(0.07)

    static let streakGradient = LinearGradient(
        colors: [flameL1, Color(hex: 0xFF5D3B)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let hoverOverlay = Color.white.opacity(0.08)
    static let dividerColor = Color.white.opacity(0.10)

    static let iconTileGradient = LinearGradient(
        colors: [Color(hex: 0x22252E), Color(hex: 0x15171D)],
        startPoint: .top,
        endPoint: .bottom
    )

    // Header / app-icon flame bitmap: 0 = transparent, 1/2/3 map to palette below.
    static let flameBitmap: [[Int]] = [
        [0, 0, 0, 1, 0, 0, 0],
        [0, 0, 1, 1, 1, 0, 0],
        [0, 0, 1, 2, 1, 0, 0],
        [0, 1, 2, 2, 2, 1, 0],
        [0, 1, 2, 2, 2, 2, 0],
        [1, 2, 3, 3, 3, 2, 1],
        [1, 3, 3, 3, 3, 3, 1],
        [0, 1, 3, 3, 3, 1, 0],
    ]

    static func flamePixelColor(_ value: Int) -> Color {
        switch value {
        case 1: return flameL1
        case 2: return flameL2
        case 3: return Color(hex: 0xFF5D3B)
        default: return .clear
        }
    }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
