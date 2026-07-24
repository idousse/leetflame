import SwiftUI
import AppKit

private func s(_ v: CGFloat) -> CGFloat { Theme.UI.s(v) }
private func f(_ v: CGFloat) -> CGFloat { Theme.UI.f(v) }

// Hidden mode used to generate the README screenshot from the app's own views
// with mock data. Invoke via: LeetFlame --render-screenshot <output.png>
enum ScreenshotRenderer {
    @MainActor
    static func run(outputPath: String) {
        ScreenshotMode.isActive = true
        let store = StreakStore()
        store.username = "leetcoder"
        store.stats = mockStats()
        store.lastUpdated = Date()

        let view = FramedScene(store: store).fixedSize()

        let renderer = ImageRenderer(content: view)
        renderer.scale = 2

        guard
            let nsImage = renderer.nsImage,
            let tiff = nsImage.tiffRepresentation,
            let rep = NSBitmapImageRep(data: tiff),
            let png = rep.representation(using: .png, properties: [:])
        else {
            FileHandle.standardError.write(Data("Failed to render screenshot\n".utf8))
            exit(1)
        }

        do {
            try png.write(to: URL(fileURLWithPath: outputPath))
            print("Screenshot written to \(outputPath)")
            exit(0)
        } catch {
            FileHandle.standardError.write(Data("Write failed: \(error)\n".utf8))
            exit(1)
        }
    }

    private static func mockStats() -> LeetCodeStats {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let today = cal.startOfDay(for: Date())

        var calendar: [Date: Int] = [:]
        func setDay(_ offset: Int, _ count: Int) {
            let day = cal.date(byAdding: .day, value: -offset, to: today)!
            let noon = cal.date(byAdding: .hour, value: 12, to: day)!
            calendar[noon] = count
        }

        // A real 50-day streak: consecutive days 0...49 ending today.
        for offset in 0..<50 {
            setDay(offset, Int.random(in: 1...8))
        }
        // Days 50 and 51 stay empty so the streak stops at exactly 50, then
        // scattered earlier activity fills out the rest of the heatmap window.
        for offset in 52..<130 where Bool.random() {
            setDay(offset, Int.random(in: 1...9))
        }

        return LeetCodeStats(
            username: "leetcoder",
            streak: 50,
            totalActiveDays: 137,
            totalSolved: 342,
            easySolved: 156,
            mediumSolved: 160,
            hardSolved: 26,
            submissionCalendar: calendar
        )
    }
}

// MARK: - Framed "in the menu bar" scene

/// Composes the popover under a faux macOS menu bar over a desktop wallpaper,
/// so the README screenshot reads clearly as a menu-bar app.
private struct FramedScene: View {
    @ObservedObject var store: StreakStore

    // Horizontal margins around the popover, and where the pointer sits.
    private let sideMargin: CGFloat = 44
    private let popoverTrailing: CGFloat = 44
    private let pointerTrailing: CGFloat = 166 // pointer inset from popover's right edge

    private var popoverWidth: CGFloat { s(440) }
    private var canvasWidth: CGFloat { popoverWidth + s(sideMargin) * 2 }
    // Distance of the pointer (and the menu-bar flame) from the canvas right edge.
    private var anchorFromRight: CGFloat { s(popoverTrailing) + s(pointerTrailing) }

    var body: some View {
        VStack(spacing: 0) {
            MenuBar(flameFromRight: anchorFromRight)
                .frame(width: canvasWidth)

            popover
                .frame(width: canvasWidth, alignment: .trailing)
                .padding(.trailing, s(popoverTrailing))
                .padding(.top, s(6))

            Spacer(minLength: s(34))
        }
        .frame(width: canvasWidth)
        .background(Wallpaper())
    }

    private var popover: some View {
        VStack(spacing: 0) {
            UpTriangle()
                .fill(Color(hex: 0x24262C))
                .frame(width: s(22), height: s(11))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, s(pointerTrailing - 11))
            ContentView(store: store, onOpenSettings: {}, onOpenAbout: {}, onQuit: {})
        }
        .fixedSize()
    }
}

private struct Wallpaper: View {
    var body: some View {
        LinearGradient(
            colors: [Color(hex: 0x2B5876), Color(hex: 0x3A4A78), Color(hex: 0x4E4376)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct UpTriangle: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

private struct MenuBar: View {
    let flameFromRight: CGFloat

    var body: some View {
        ZStack(alignment: .leading) {
            Color.black.opacity(0.32)

            // Left: app menus.
            HStack(spacing: s(16)) {
                Image(systemName: "apple.logo")
                    .font(.system(size: f(13)))
                Text("LeetFlame").fontWeight(.semibold)
                Text("File")
                Text("Edit")
                Text("View")
            }
            .font(.system(size: f(12.5)))
            .foregroundColor(.white.opacity(0.92))
            .padding(.leading, s(14))

            // Right: system status items + clock.
            HStack(spacing: s(15)) {
                Image(systemName: "wifi")
                Image(systemName: "battery.100")
                Image(systemName: "switch.2")
                Text("2:14 PM")
            }
            .font(.system(size: f(12)))
            .foregroundColor(.white.opacity(0.92))
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, s(14))

            // The LeetFlame status item, highlighted as if the popover is open.
            HStack(spacing: s(4)) {
                PixelFlameView(cellSize: s(1.9), gap: s(0.8))
                Text("50")
                    .font(.system(size: f(12), weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, s(6))
            .padding(.vertical, s(3))
            .background(RoundedRectangle(cornerRadius: s(5)).fill(Color.white.opacity(0.20)))
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, flameFromRight - s(20))
        }
        .frame(height: s(30))
    }
}
