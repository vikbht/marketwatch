import Cocoa

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// Runs purely as a status bar application without showing a Dock icon
app.setActivationPolicy(.accessory)

// Launch loop
app.run()
