import Foundation
import Combine
import ServiceManagement

final class StreakStore: ObservableObject {
    @Published var stats: LeetCodeStats?
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var lastUpdated: Date?
    @Published var username: String {
        didSet { UserDefaults.standard.set(username, forKey: Keys.username) }
    }
    @Published var opacity: Double {
        didSet { UserDefaults.standard.set(opacity, forKey: Keys.opacity) }
    }
    @Published var refreshIntervalMinutes: Double {
        didSet {
            UserDefaults.standard.set(refreshIntervalMinutes, forKey: Keys.refreshInterval)
            startAutoRefresh(intervalMinutes: refreshIntervalMinutes)
        }
    }
    @Published var showStreakInMenuBar: Bool {
        didSet { UserDefaults.standard.set(showStreakInMenuBar, forKey: Keys.showStreakInMenuBar) }
    }
    @Published var launchAtLogin: Bool {
        didSet {
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                // Revert silently if the system refused (e.g. running outside /Applications).
                launchAtLoginError = error.localizedDescription
                launchAtLogin = SMAppService.mainApp.status == .enabled
            }
        }
    }
    @Published var launchAtLoginError: String?

    private enum Keys {
        static let username = "leetcodeUsername"
        static let opacity = "popoverOpacity"
        static let refreshInterval = "refreshIntervalMinutes"
        static let showStreakInMenuBar = "showStreakInMenuBar"
    }

    private let api = LeetCodeAPI()
    private var refreshTimer: Timer?

    init() {
        self.username = UserDefaults.standard.string(forKey: Keys.username) ?? ""
        let storedOpacity = UserDefaults.standard.object(forKey: Keys.opacity) as? Double
        self.opacity = storedOpacity ?? 0.82
        let storedInterval = UserDefaults.standard.object(forKey: Keys.refreshInterval) as? Double
        self.refreshIntervalMinutes = storedInterval ?? 30
        let storedShowStreak = UserDefaults.standard.object(forKey: Keys.showStreakInMenuBar) as? Bool
        self.showStreakInMenuBar = storedShowStreak ?? true
        self.launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    func startAutoRefresh(intervalMinutes: Double) {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: max(intervalMinutes, 1) * 60, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    func refresh() {
        guard !username.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Set your LeetCode username"
            return
        }
        isLoading = true
        errorMessage = nil
        let usernameToFetch = username
        Task {
            do {
                let result = try await api.fetchStats(username: usernameToFetch)
                self.stats = result
                self.lastUpdated = Date()
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    // LeetCode's submissionCalendar keys are UTC-midnight timestamps, so days must be
    // bucketed with a UTC calendar or every submission shifts a day in western timezones.
    private static let utcCalendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    private func dailyCountsByDay() -> [DateComponents: Int] {
        guard let stats else { return [:] }
        var counts: [DateComponents: Int] = [:]
        for (date, count) in stats.submissionCalendar {
            let key = Self.utcCalendar.dateComponents([.year, .month, .day], from: date)
            counts[key, default: 0] += count
        }
        return counts
    }

    private func dayKey(for localDate: Date) -> DateComponents {
        Calendar.current.dateComponents([.year, .month, .day], from: localDate)
    }

    // "Today" and the streak walk use UTC days to match LeetCode's own daily
    // reset (UTC midnight), not the local calendar day.
    private func utcDayKey(for date: Date) -> DateComponents {
        Self.utcCalendar.dateComponents([.year, .month, .day], from: date)
    }

    var solvedToday: Bool {
        (dailyCountsByDay()[utcDayKey(for: Date())] ?? 0) > 0
    }

    /// Consecutive days with submissions ending today (or yesterday — an unsolved
    /// today doesn't break the streak yet). The API's own `streak` field is the
    /// year's longest streak, not the current one.
    var currentStreak: Int {
        let counts = dailyCountsByDay()
        let cal = Self.utcCalendar
        var day = cal.startOfDay(for: Date())
        var streak = 0
        if (counts[utcDayKey(for: day)] ?? 0) > 0 {
            streak += 1
        }
        while true {
            day = cal.date(byAdding: .day, value: -1, to: day)!
            if (counts[utcDayKey(for: day)] ?? 0) > 0 {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }

    /// 18 columns (weeks, oldest first) x 7 rows (Mon...Sun); levels use quartile
    /// thresholds from the user's own nonzero-day distribution.
    var heatmap: HeatmapData {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let totalDays = 18 * 7

        // Align the grid so the last column ends on the current week, Monday-first rows.
        let weekday = cal.component(.weekday, from: today) // 1 = Sunday ... 7 = Saturday
        let mondayIndex = (weekday + 5) % 7 // 0 = Monday
        let gridEnd = cal.date(byAdding: .day, value: 6 - mondayIndex, to: today)!
        let gridStart = cal.date(byAdding: .day, value: -(totalDays - 1), to: gridEnd)!

        let countsByDay = dailyCountsByDay()

        var days: [(date: Date, count: Int)] = []
        for offset in 0..<totalDays {
            let day = cal.date(byAdding: .day, value: offset, to: gridStart)!
            let count = day > today ? -1 : (countsByDay[dayKey(for: day)] ?? 0)
            days.append((day, count))
        }

        let nonZero = days.map(\.count).filter { $0 > 0 }.sorted()
        func quartile(_ p: Double) -> Int {
            guard !nonZero.isEmpty else { return 0 }
            let idx = min(nonZero.count - 1, max(0, Int(Double(nonZero.count - 1) * p)))
            return nonZero[idx]
        }
        let q1 = max(1, quartile(0.25))
        let q2 = max(q1, quartile(0.5))
        let q3 = max(q2, quartile(0.75))

        func level(for count: Int) -> Int {
            if count <= 0 { return 0 }
            if count <= q1 { return 1 }
            if count <= q2 { return 2 }
            if count <= q3 { return 3 }
            return 4
        }

        var columns: [[HeatmapCell]] = []
        for col in 0..<18 {
            var rows: [HeatmapCell] = []
            for row in 0..<7 {
                let day = days[col * 7 + row]
                rows.append(HeatmapCell(
                    date: day.date,
                    count: max(0, day.count),
                    level: day.count < 0 ? 0 : level(for: day.count),
                    isFuture: day.count < 0
                ))
            }
            columns.append(rows)
        }

        // GitHub-style month labels: one above each week column whose Monday starts
        // a new month, so labels sit at the real month boundaries.
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMM"
        var monthLabels: [String?] = []
        var previousMonth = -1
        for column in columns {
            let month = cal.component(.month, from: column[0].date)
            monthLabels.append(month != previousMonth ? formatter.string(from: column[0].date) : nil)
            previousMonth = month
        }
        // Drop a leading label that would collide with the next one right beside it.
        if monthLabels.count > 1, monthLabels[0] != nil, monthLabels[1] != nil {
            monthLabels[0] = nil
        }

        return HeatmapData(columns: columns, monthLabels: monthLabels)
    }
}

struct HeatmapCell {
    let date: Date
    let count: Int
    let level: Int
    let isFuture: Bool
}

struct HeatmapData {
    let columns: [[HeatmapCell]]
    /// One entry per week column; non-nil where a month label should appear.
    let monthLabels: [String?]
}
