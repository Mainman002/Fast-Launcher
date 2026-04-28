import Cocoa
import HotKey

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var hotKey: HotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        // 1. Your existing HotKey setup
        hotKey = HotKey(key: .space, modifiers: [.command, .shift])
        hotKey?.keyDownHandler = { [weak self] in
            self?.showLauncher()
        }

        // 2. Add the Escape Key Monitor
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // 53 is the code for Escape
                self?.hideLauncher()
                return nil // Handled: don't pass the event further
            }
            return event // Pass all other keys (letters, numbers) to the search bar
        }
    }

    func hideLauncher() {
        // 1. Clear the search so it's fresh for next time
        // You'll need to reach into your LauncherModel here
        
        // 2. Hide the window
        NSApp.hide(nil)
        
        // 3. Optional: Resign key status to ensure focus returns to your IDE/Engine
        NSApp.windows.first?.orderOut(nil)
    }

    func showLauncher() {
        NSApp.activate(ignoringOtherApps: true)

        guard let window = NSApp.windows.first else { return }

        // 1. Set the style mask to be borderless
        // We keep .fullSizeContentView to ensure your blur effect fills the whole area
        window.styleMask = [.borderless, .fullSizeContentView]
        
        // 2. Hide the title bar completely
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        
        // 3. Standard floating behavior
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // 4. Appearance tweaks
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        
        // 5. Allow dragging the window from the background (since there's no title bar)
        window.isMovableByWindowBackground = true

        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let windowSize = window.frame.size

        let x = screenFrame.midX - windowSize.width / 2
        let y = screenFrame.midY - windowSize.height / 2

        window.setFrameOrigin(NSPoint(x: x, y: y))
        window.makeKeyAndOrderFront(nil)
        
        // Ensure shadow is recalculated for the new borderless shape
        window.invalidateShadow()
    }
}
