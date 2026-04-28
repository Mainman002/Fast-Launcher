import Foundation
import AppKit

struct AppEntry: Identifiable, Hashable {
    let id: String
    let name: String
    let path: String
    let bundleID: String?
    let icon: NSImage

    func hash(into hasher: inout Hasher) {
        hasher.combine(path)
    }

    static func == (lhs: AppEntry, rhs: AppEntry) -> Bool {
        lhs.path == rhs.path
    }
}
