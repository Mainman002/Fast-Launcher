import Cocoa
import HotKey

class LauncherWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var hotKey: HotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        hotKey = HotKey(key: .space, modifiers: [.command, .shift])
        hotKey?.keyDownHandler = { [weak self] in
            self?.showLauncher()
        }

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Escape
                self?.hideLauncher()
                return nil
            }
            return event
        }
    }

    func hideLauncher() {
        NSApp.hide(nil)
        NSApp.windows.first?.orderOut(nil)
    }

    func showLauncher() {
        NSApp.activate(ignoringOtherApps: true)
        guard let window = NSApp.windows.first else { return }

        // Configuration for the "Spotlight" look
        window.styleMask = [.titled, .fullSizeContentView]
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        
        // Fix for your error: Use .zoomButton here 💡
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true

        window.level = .floating
        window.isMovableByWindowBackground = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true

        // Center on screen
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let windowSize = window.frame.size
        let x = screenFrame.midX - windowSize.width / 2
        let y = screenFrame.midY - windowSize.height / 2

        window.setFrameOrigin(NSPoint(x: x, y: y))
        
        // Focus and Refresh
        window.makeKeyAndOrderFront(nil)
        window.invalidateShadow()
    }
}
