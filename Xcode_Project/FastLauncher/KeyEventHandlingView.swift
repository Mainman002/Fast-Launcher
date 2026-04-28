import SwiftUI
import AppKit

struct KeyEventHandlingView: NSViewRepresentable {

    let onEscape: () -> Void
    let onUpArrow: () -> Void
    let onDownArrow: () -> Void
    let onEnter: () -> Void

    func makeNSView(context: Context) -> NSView {
        let view = KeyCatcherView()
        view.onEscape = onEscape
        view.onUpArrow = onUpArrow
        view.onDownArrow = onDownArrow
        view.onEnter = onEnter
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    final class KeyCatcherView: NSView {

        var onEscape: (() -> Void)?
        var onUpArrow: (() -> Void)?
        var onDownArrow: (() -> Void)?
        var onEnter: (() -> Void)?

        override var acceptsFirstResponder: Bool { true }

        override func keyDown(with event: NSEvent) {
            switch event.keyCode {
            case 53: // Escape
                onEscape?()

            case 125: // Down arrow
                onDownArrow?()

            case 126: // Up arrow
                onUpArrow?()

            case 36, 76: // Enter / Numpad Enter
                onEnter?()

            default:
                super.keyDown(with: event)
            }
        }
    }
}
