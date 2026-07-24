import AppKit
import SwiftUI
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var settingsWindow: NSWindow?
    private var aboutWindow: NSWindow?
    private let store = StreakStore()
    private var cancellable: AnyCancellable?
    private let flameIconLit = FlameIconRenderer.makeStatusIcon()
    private let flameIconDim = FlameIconRenderer.makeStatusIcon(grayscale: true)

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hidden screenshot mode: render docs/screenshot.png and exit.
        if let idx = CommandLine.arguments.firstIndex(of: "--render-screenshot"),
           idx + 1 < CommandLine.arguments.count {
            ScreenshotRenderer.run(outputPath: CommandLine.arguments[idx + 1])
            return
        }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = flameIconDim
        statusItem.button?.imagePosition = .imageLeading
        statusItem.button?.title = " –"
        statusItem.button?.action = #selector(togglePopover)
        statusItem.button?.target = self

        popover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = NSSize(width: Theme.UI.s(440), height: Theme.UI.s(560))
        popover.contentViewController = NSHostingController(
            rootView: ContentView(
                store: store,
                onOpenSettings: { [weak self] in self?.showSettings() },
                onOpenAbout: { [weak self] in self?.showAbout() },
                onQuit: { NSApp.terminate(nil) }
            )
        )

        cancellable = store.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async { self?.updateStatusTitle() }
        }

        store.refresh()
        store.startAutoRefresh(intervalMinutes: store.refreshIntervalMinutes)
    }

    private func updateStatusTitle() {
        // Light the flame only once today's question is solved; dim otherwise.
        statusItem.button?.image = store.solvedToday ? flameIconLit : flameIconDim

        guard store.showStreakInMenuBar else {
            statusItem.button?.title = ""
            return
        }
        if store.stats != nil {
            statusItem.button?.title = " \(store.currentStreak)"
        } else if store.errorMessage != nil {
            statusItem.button?.title = " !"
        } else {
            statusItem.button?.title = " –"
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func showSettings() {
        popover.performClose(nil)
        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 320, height: 260),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "LeetFlame Settings"
            window.contentViewController = NSHostingController(rootView: SettingsView(store: store))
            window.isReleasedWhenClosed = false
            settingsWindow = window
        }
        settingsWindow?.center()
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func showAbout() {
        popover.performClose(nil)
        if aboutWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 260, height: 240),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "About LeetFlame"
            window.contentViewController = NSHostingController(rootView: AboutView())
            window.isReleasedWhenClosed = false
            aboutWindow = window
        }
        aboutWindow?.center()
        aboutWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
