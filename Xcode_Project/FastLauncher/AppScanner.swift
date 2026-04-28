import Foundation
import AppKit

final class AppScanner {
    
    static func scanApplications() -> [AppEntry] {
        let fileManager = FileManager.default
        
        let appDirs: [URL] = [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/System/Applications"),
            fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
        ]
        
        var foundApps: [AppEntry] = []
        var seenPaths: Set<String> = []
        
        for dir in appDirs {
            guard (try? dir.checkResourceIsReachable()) == true else { continue }
            
            // Fixed: changed .skipsUserVisibleDotFiles to .skipsHiddenFiles
            let options: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles, .skipsPackageDescendants]
            
            if let enumerator = fileManager.enumerator(at: dir, includingPropertiesForKeys: [.isApplicationKey], options: options) {
                for case let fileURL as URL in enumerator {
                    if fileURL.pathExtension.lowercased() == "app" {
                        let path = fileURL.path
                        if seenPaths.contains(path) { continue }
                        seenPaths.insert(path)
                        
                        if let entry = buildEntry(forAppURL: fileURL) {
                            foundApps.append(entry)
                        }
                        enumerator.skipDescendants()
                    }
                }
            }
        }
        return foundApps.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
    
    private static func buildEntry(forAppURL url: URL) -> AppEntry? {
        // 1. Get the localized name from resource values (this key is stable)
        let resourceValues = try? url.resourceValues(forKeys: [.localizedNameKey])
        let name = resourceValues?.localizedName ?? url.deletingPathExtension().lastPathComponent
        let path = url.path
        
        // 2. Get the Bundle ID safely using the Bundle object
        // This avoids the 'bundleIdentifierKey' compiler error entirely
        let bundleID = Bundle(url: url)?.bundleIdentifier
        
        let icon = loadIcon(appURL: url, bundleID: bundleID)
        
        return AppEntry(
            id: path,
            name: name,
            path: path,
            bundleID: bundleID,
            icon: icon
        )
    }
    
    private static func loadIcon(appURL: URL, bundleID: String?) -> NSImage {
        // Check for custom icons in your FastLauncher support folder first
        if let bID = bundleID,
           let overrideIcon = IconOverrides.loadOverrideIcon(bundleID: bID) {
            return overrideIcon
        }
        
        // Default: Use the system-provided icon for the file path
        return NSWorkspace.shared.icon(forFile: appURL.path)
    }
}
