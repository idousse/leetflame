import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 25)
                .fill(Theme.iconTileGradient)
                .frame(width: 108, height: 108)
                .overlay(PixelFlameView(cellSize: 9, gap: 2))

            Text("LeetFlame")
                .font(.system(size: 19, weight: .semibold))
            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev")")
                .font(.system(size: 12.5))
                .foregroundColor(Theme.textTertiary)
            Text("A menu-bar streak tracker for LeetCode.")
                .font(.system(size: 13))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .frame(width: 280)
    }
}
