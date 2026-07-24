import AppKit

let app = NSApplication.shared
// Screenshot mode still needs a launched app; AppDelegate handles it in
// applicationDidFinishLaunching and exits when done.
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
