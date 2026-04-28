import Foundation
import AppKit

final class IconOverrides {

    static func overrideFolder() -> URL {
        let fm = FileManager.default
        let base = fm.homeDirectoryForCurrentUser
            .appendingPathComponent("Library")
            .appendingPathComponent("Application Support")
            .appendingPathComponent("FastLauncher")
            .appendingPathComponent("icons")

        if !fm.fileExists(atPath: base.path) {
            try? fm.createDirectory(at: base, withIntermediateDirectories: true)
        }

        return base
    }

    static func loadOverrideIcon(bundleID: String) -> NSImage? {
        let folder = overrideFolder()

        let png = folder.appendingPathComponent("\(bundleID).png")
        let jpg = folder.appendingPathComponent("\(bundleID).jpg")
        let jpeg = folder.appendingPathComponent("\(bundleID).jpeg")

        if FileManager.default.fileExists(atPath: png.path),
           let img = NSImage(contentsOf: png) {
            return img
        }

        if FileManager.default.fileExists(atPath: jpg.path),
           let img = NSImage(contentsOf: jpg) {
            return img
        }

        if FileManager.default.fileExists(atPath: jpeg.path),
           let img = NSImage(contentsOf: jpeg) {
            return img
        }

        return nil
    }
}
