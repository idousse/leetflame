# 🔥 LeetFlame

A native macOS menu-bar app that shows your LeetCode activity at a glance:
current streak, active days, total solved, difficulty breakdown, and a
GitHub-style contribution heatmap rendered as a flame gradient.

No login required — it reads your public profile via LeetCode's GraphQL API.

## Features

- **Menu-bar popover** with current streak, active days, and total solved
- **Flame heatmap** — 18 weeks of submissions, colored on a pale-yellow → deep-red scale
- **Difficulty breakdown** (Easy / Medium / Hard)
- **Daily status** — "Solved today" / "Not solved today"
- **Hover tooltips** — submission count per day
- **Auto-refresh** on a configurable interval (5–120 min)
- **Settings**: username, popover opacity, refresh interval, launch-at-login,
  and an icon-only menu-bar mode
- Everything persists locally via `UserDefaults` — no account, no backend

## How it works

LeetFlame queries LeetCode's public GraphQL endpoint
(`https://leetcode.com/graphql`) for `matchedUser.userCalendar` and
`submitStatsGlobal`. The **current streak** is computed locally from the
submission calendar (LeetCode's own `streak` field is the *year's longest*
streak, not the current one). Days are bucketed in UTC to match LeetCode's
daily reset.

## Requirements

- macOS 13 (Ventura) or later
- Swift toolchain (Xcode or Command Line Tools) to build

## Build & install

```bash
# Build the .app bundle into .build/release/
./build_app.sh

# ...or build, copy to /Applications, and (re)launch:
./build_app.sh --install
```

Then open the app, click the flame in your menu bar, and enter your LeetCode
username.

### Regenerating the app icon

The icon is drawn from a pixel-flame bitmap:

```bash
swift scripts/generate_icon.swift AppIcon.iconset
iconutil -c icns AppIcon.iconset -o Assets/AppIcon.icns
```

## A note on distribution

The build uses an **ad-hoc code signature**, which is fine for personal use.
To share the app so it opens without a Gatekeeper warning, you'd need to sign
it with an Apple Developer ID and notarize it. Until then, other users can
right-click the app → **Open** to bypass the warning on first launch.

## Project structure

| File | Responsibility |
|---|---|
| `LeetCodeAPI.swift` | GraphQL fetch + response parsing |
| `StreakStore.swift` | State, persistence, streak/heatmap computation |
| `AppDelegate.swift` | Status item, popover, settings/about windows |
| `ContentView.swift` | Main popover UI |
| `HeatmapView.swift` | Contribution heatmap |
| `SettingsView.swift` / `AboutView.swift` | Preferences and about panels |
| `PixelFlameView.swift` | Flame logo/icon rendering |
| `Theme.swift` | Colors, gradients, design tokens |

## License

[MIT](LICENSE) © Ioann Dousse
