import SwiftUI
import AppKit

struct ContentView: View {
    @ObservedObject var store: StreakStore
    var onOpenSettings: () -> Void
    var onOpenAbout: () -> Void
    var onQuit: () -> Void
    @State private var usernameInput: String = ""
    @FocusState private var usernameFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.bottom, 20)

            if store.username.trimmingCharacters(in: .whitespaces).isEmpty {
                onboardingPrompt
                    .padding(.bottom, 20)
            } else if store.isLoading && store.stats == nil {
                ProgressView()
                    .padding(.bottom, 20)
            } else if let error = store.errorMessage, store.stats == nil {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textSecondary)
                    .padding(.bottom, 20)
            } else if let stats = store.stats {
                statsRow(stats)
                    .padding(.bottom, 20)
                difficultyRow(stats)
                    .padding(.bottom, 18)
                HeatmapView(data: store.heatmap)
                    .padding(.bottom, 18)
                dailyStatusRow
                    .padding(.bottom, 6)
                freshnessRow
            }

            Divider().overlay(Theme.dividerColor).padding(.vertical, 12)

            if !store.username.trimmingCharacters(in: .whitespaces).isEmpty {
                MenuRow.profileRow(handle: "@\(store.username)") {
                    if let url = URL(string: "https://leetcode.com/\(store.username)/") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
            MenuRow(title: "Settings", action: onOpenSettings)
            MenuRow(title: "About LeetFlame", action: onOpenAbout)

            Divider().overlay(Theme.dividerColor).padding(.vertical, 12)

            MenuRow(title: "Quit", action: onQuit)
                .padding(.bottom, 4)
        }
        .padding(EdgeInsets(top: 22, leading: 22, bottom: 14, trailing: 22))
        .frame(width: 440)
        .background(PopoverBackground(opacity: store.opacity))
        .foregroundColor(Theme.textPrimary)
        .onAppear {
            usernameInput = store.username
            if store.stats == nil && !store.username.trimmingCharacters(in: .whitespaces).isEmpty {
                store.refresh()
            }
        }
    }

    private var header: some View {
        HStack(spacing: 11) {
            HeaderIconTile()
            Text("LeetFlame")
                .font(.system(size: 19, weight: .semibold))
                .tracking(-0.2)
        }
    }

    private var onboardingPrompt: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Enter your LeetCode username to get started")
                .font(.system(size: 14))
                .foregroundColor(Theme.textMenu)
            HStack {
                TextField("your LeetCode username", text: $usernameInput)
                    .textFieldStyle(.roundedBorder)
                    .focused($usernameFieldFocused)
                    .onSubmit(saveUsername)
                Button("Get Started", action: saveUsername)
                    .disabled(usernameInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .onAppear { usernameFieldFocused = true }
    }

    private func saveUsername() {
        let trimmed = usernameInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        store.username = trimmed
        store.refresh()
    }

    private func statsRow(_ stats: LeetCodeStats) -> some View {
        HStack(spacing: 8) {
            statColumn {
                Text("\(store.currentStreak)")
                    .font(.system(size: 34, weight: .bold))
                    .tracking(-1)
                    .foregroundStyle(Theme.streakGradient)
            } label: { "Streak" }
            statColumn {
                Text("\(stats.totalActiveDays)")
                    .font(.system(size: 34, weight: .bold))
                    .tracking(-1)
            } label: { "Active days" }
            statColumn {
                Text("\(stats.totalSolved)")
                    .font(.system(size: 34, weight: .bold))
                    .tracking(-1)
            } label: { "Solved" }
        }
    }

    @ViewBuilder
    private func statColumn<Content: View>(@ViewBuilder content: () -> Content, label: () -> String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            content()
            Text(label())
                .font(.system(size: 13))
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func difficultyRow(_ stats: LeetCodeStats) -> some View {
        HStack(spacing: 24) {
            difficultyItem("Easy", stats.easySolved)
            difficultyItem("Medium", stats.mediumSolved)
            difficultyItem("Hard", stats.hardSolved)
        }
        .font(.system(size: 14.5))
    }

    private func difficultyItem(_ label: String, _ count: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 7) {
            Text(label).foregroundColor(Theme.difficultyLabel)
            Text("\(count)").fontWeight(.bold)
        }
    }

    private var freshnessRow: some View {
        HStack(spacing: 6) {
            if let error = store.errorMessage, store.stats != nil {
                Text("Refresh failed — showing older data (\(error))")
                    .foregroundColor(Theme.flameL3)
            } else if let updated = store.lastUpdated {
                Text("Updated \(updated.formatted(date: .omitted, time: .shortened))")
                    .foregroundColor(Theme.textTertiary)
            }
        }
        .font(.system(size: 11))
    }

    private var dailyStatusRow: some View {
        HStack(spacing: 10) {
            if store.solvedToday {
                StatusRing(symbol: "checkmark", color: Theme.flameL1)
                Text("Solved today")
                    .foregroundColor(Theme.textMenu)
            } else {
                StatusRing(symbol: "xmark", color: Theme.flameL4)
                Text("Not solved today")
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .font(.system(size: 15))
    }
}

private struct StatusRing: View {
    let symbol: String
    let color: Color
    var body: some View {
        ZStack {
            Circle().stroke(color, lineWidth: 2)
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .black))
                .foregroundColor(color)
        }
        .frame(width: 21, height: 21)
    }
}

private struct MenuRow: View {
    let title: String
    var subtitle: String? = nil
    var trailingGlyph: String? = nil
    let action: () -> Void
    @State private var hovering = false

    static func profileRow(handle: String, action: @escaping () -> Void) -> MenuRow {
        MenuRow(title: "View LeetCode Profile", subtitle: handle, trailingGlyph: "arrow.up.right", action: action)
    }

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 15))
                        .foregroundColor(Theme.textMenu)
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 12.5))
                            .foregroundColor(Theme.textTertiary)
                    }
                }
                Spacer()
                if let trailingGlyph {
                    Image(systemName: trailingGlyph)
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textAxis)
                }
            }
            .padding(EdgeInsets(top: 9, leading: 10, bottom: 9, trailing: 10))
            .background(hovering ? Theme.hoverOverlay : Color.clear)
            .cornerRadius(9)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

private struct PopoverBackground: View {
    let opacity: Double
    var body: some View {
        ZStack {
            // ImageRenderer (screenshot mode) can't capture an NSVisualEffectView,
            // so use an opaque approximation of the blurred surface instead.
            if ScreenshotMode.isActive {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(hex: 0x24262C))
            } else {
                VisualEffectBlur()
            }
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(hex: 0x2C2E34, alpha: opacity))
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.5), radius: 40, x: 0, y: 30)
    }
}

/// Set while rendering the README screenshot so views can avoid AppKit-backed
/// content that ImageRenderer cannot capture.
enum ScreenshotMode {
    static var isActive = false
}

private struct VisualEffectBlur: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.state = .active
        view.material = .fullScreenUI
        return view
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
