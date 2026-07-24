import SwiftUI
import AppKit

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

        let view = ZStack {
            Color(hex: 0x0E0E10)
            ContentView(store: store, onOpenSettings: {}, onOpenAbout: {}, onQuit: {})
        }
        .frame(width: Theme.UI.s(440))
        .fixedSize()

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
