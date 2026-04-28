import Foundation
import HotKey
import AppKit

final class HotKeyManager {

    static let shared = HotKeyManager()

    private var hotKey: HotKey?

    private init() {
        hotKey = HotKey(key: .space, modifiers: [.command, .shift])

        hotKey?.keyDownHandler = {
            NSApp.activate(ignoringOtherApps: true)

            for window in NSApp.windows {
                window.makeKeyAndOrderFront(nil)
            }
        }
    }
}
