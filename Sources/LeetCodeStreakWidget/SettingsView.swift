import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: StreakStore
    @State private var usernameDraft: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            section("Account") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("LeetCode username")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                    HStack {
                        TextField("e.g. loio432", text: $usernameDraft)
                            .textFieldStyle(.plain)
                            .padding(EdgeInsets(top: 6, leading: 9, bottom: 6, trailing: 9))
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(7)
                            .onSubmit(applyUsername)
                        Button("Apply", action: applyUsername)
                            .disabled(usernameDraft.trimmingCharacters(in: .whitespaces) == store.username)
                    }
                }
            }

            section("Appearance") {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Popover opacity — \(Int(store.opacity * 100))%")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textSecondary)
                        Slider(value: $store.opacity, in: 0.30...1.0)
                    }
                    Toggle("Show streak number in menu bar", isOn: $store.showStreakInMenuBar)
                        .font(.system(size: 13))
                }
            }

            section("Behavior") {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Refresh every \(Int(store.refreshIntervalMinutes)) min")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textSecondary)
                        Slider(value: $store.refreshIntervalMinutes, in: 5...120, step: 5)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("Launch at login", isOn: $store.launchAtLogin)
                            .font(.system(size: 13))
                        if let error = store.launchAtLoginError {
                            Text(error)
                                .font(.system(size: 11))
                                .foregroundColor(Theme.flameL4)
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .toggleStyle(.switch)
        .controlSize(.small)
        .tint(Theme.flameL2)
        .padding(20)
        .frame(width: 340)
        .background(Color(hex: 0x1D1F24))
        .foregroundColor(Theme.textPrimary)
        .onAppear { usernameDraft = store.username }
    }

    private func applyUsername() {
        let trimmed = usernameDraft.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed != store.username else { return }
        store.username = trimmed
        store.refresh()
    }

    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 10.5, weight: .semibold))
                .tracking(0.8)
                .foregroundColor(Theme.textTertiary)
            content()
        }
    }
}
