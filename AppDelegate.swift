import Cocoa
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var fetcher = MarketBreadthFetcher()
    var hudWindow: HUDPanel?
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.title = "📊 Loading..."
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
        
        // Listen to changes in breadth items to dynamically update the menu bar title
        fetcher.$items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                guard let self = self else { return }
                
                var titleString = ""
                
                // 1. Get Advancing % (Breadth)
                if let advancingItem = items.first(where: { $0.title.contains("Advancing") }) {
                    let leftVal = advancingItem.leftValue
                    let components = leftVal.components(separatedBy: " ")
                    if let rawPercent = components.first, !rawPercent.isEmpty {
                        titleString += "📊 \(rawPercent)"
                    }
                }
                
                if titleString.isEmpty {
                    self.statusItem.button?.title = "📊 Load..."
                } else {
                    self.statusItem.button?.title = titleString
                }
            }
            .store(in: &cancellables)
            
        // Create the SwiftUI visual dashboard
        let dashboardView = BreadthDashboardView(fetcher: fetcher)
        
        // Setup NSPopover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 1080, height: 380)
        popover.behavior = .transient // Automatically closes when clicking away
        popover.contentViewController = NSHostingController(rootView: dashboardView)
        
        // Parse custom refresh interval from command-line arguments (default is 300 seconds)
        var interval: TimeInterval = 300
        let args = CommandLine.arguments
        if let index = args.firstIndex(of: "--interval") ?? args.firstIndex(of: "-i"),
           index + 1 < args.count,
           let parsedInterval = TimeInterval(args[index + 1]) {
            // Safety: limit the minimum interval to 10 seconds to avoid aggressive rate-limiting
            interval = max(10, parsedInterval)
        }
        
        print("Refresh interval set to \(interval) seconds")
        
        // Initial Fetch
        fetcher.fetch()
        
        // Schedule auto-refresh
        refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.fetcher.fetch()
        }
        
        
        // Listen for screenshot requests from SwiftUI view
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(takeScreenshot),
            name: Notification.Name("TakeScreenshot"),
            object: nil
        )
        
        // Listen for HUD window toggling requests from SwiftUI view
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(toggleHUDWindow),
            name: Notification.Name("ToggleHUDWindow"),
            object: nil
        )
    }
    
    @objc func takeScreenshot() {
        guard let view = popover.contentViewController?.view else { return }
        
        // Perform display capture on main thread
        DispatchQueue.main.async {
            guard let imageRepresentation = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return }
            view.cacheDisplay(in: view.bounds, to: imageRepresentation)
            
            let nsImage = NSImage(size: view.bounds.size)
            nsImage.addRepresentation(imageRepresentation)
            
            // Copy to Clipboard for fast pasting
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.writeObjects([nsImage])
            
            // Audio feedback
            NSSound.beep()
        }
    }
    
    @objc func toggleHUDWindow() {
        if let window = hudWindow, window.isVisible {
            // Close HUD Window and show normal popover
            window.orderOut(nil)
            hudWindow = nil
            
            if let button = statusItem.button {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        } else {
            // Close popover
            if popover.isShown {
                popover.performClose(nil)
            }
            
            // Create panel
            let rect = NSRect(x: 0, y: 0, width: 1080, height: 380)
            let window = HUDPanel(contentRect: rect)
            window.center()
            window.delegate = self
            
            let dashboardView = BreadthDashboardView(fetcher: fetcher, isWindowMode: true)
            let hostingView = NSHostingView(rootView: dashboardView)
            hostingView.frame = rect
            hostingView.autoresizingMask = [.width, .height]
            
            window.contentView?.addSubview(hostingView)
            window.makeKeyAndOrderFront(nil)
            self.hudWindow = window
        }
    }
    
    func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? HUDPanel, window == hudWindow {
            hudWindow = nil
        }
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                
                // Keep popover focused and interactive
                if let window = popover.contentViewController?.view.window {
                    window.makeKey()
                }
            }
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        refreshTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
}

class HUDPanel: NSPanel {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .resizable, .utilityWindow, .nonactivatingPanel, .hudWindow],
            backing: .buffered,
            defer: false
        )
        self.isFloatingPanel = true
        self.level = .floating
        self.title = "MarketWatch Dashboard"
        self.isMovableByWindowBackground = true
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = true
        
        let effectView = NSVisualEffectView(frame: contentRect)
        effectView.material = .hudWindow
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        effectView.autoresizingMask = [.width, .height]
        self.contentView = effectView
    }
}
