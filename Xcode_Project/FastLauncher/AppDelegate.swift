import Cocoa
import HotKey

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var hotKey: HotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        hotKey = HotKey(key: .space, modifiers: [.command, .shift])

        hotKey?.keyDownHandler = { [weak self] in
            self?.showLauncher()
        }
    }

    func showLauncher() {
        NSApp.activate(ignoringOtherApps: true)

        guard let window = NSApp.windows.first else { return }

        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true

        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let windowSize = window.frame.size

        let x = screenFrame.midX - windowSize.width / 2
        let y = screenFrame.midY - windowSize.height / 2

        window.setFrameOrigin(NSPoint(x: x, y: y))
        window.makeKeyAndOrderFront(nil)
    }
}
