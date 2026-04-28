import Foundation
import AppKit

final class AppScanner {
    
    // Updated: Accepts a path and an optional existing set to prevent duplicates across calls
    static func scanApplications(at rootPath: String? = nil, seenPaths: inout Set<String>) -> [AppEntry] {
        let fileManager = FileManager.default
        
        // 1. Resolve which directories to scan
        let appDirs: [URL]
        if let customPath = rootPath {
            appDirs = [URL(fileURLWithPath: (customPath as NSString).expandingTildeInPath)]
        } else {
            appDirs = [
                URL(fileURLWithPath: "/Applications"),
                URL(fileURLWithPath: "/System/Applications"),
                fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
            ]
        }
        
        var foundApps: [AppEntry] = []
        
        for dir in appDirs {
            var isDir: ObjCBool = false
            // Ensure the directory exists before attempting to enumerate
            guard fileManager.fileExists(atPath: dir.path, isDirectory: &isDir), isDir.boolValue else {
                print("Scanner: Skipping invalid path: \(dir.path)")
                continue
            }
            
            let options: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles, .skipsPackageDescendants]
            
            // 2. Use a generic enumerator that works for ANY folder structure
            let enumerator = fileManager.enumerator(at: dir,
                                                    includingPropertiesForKeys: [.isApplicationKey],
                                                    options: options)
            
            while let fileURL = enumerator?.nextObject() as? URL {
                // Add a quick check to see if we can actually read this URL
                // This prevents the "task name port" errors from crashing the scan
                guard (try? fileURL.checkResourceIsReachable()) == true else { continue }

                if fileURL.pathExtension.lowercased() == "app" {
                    let path = fileURL.path
                    
                    if seenPaths.contains(path) {
                        enumerator?.skipDescendants()
                        continue
                    }
                    
                    seenPaths.insert(path)
                    
                    if let entry = buildEntry(forAppURL: fileURL) {
                        foundApps.append(entry)
                    }
                    enumerator?.skipDescendants()
                }
            }
        }
        return foundApps
    }
    
    private static func buildEntry(forAppURL url: URL) -> AppEntry? {
        // 1. Check if we can actually reach the file
        guard (try? url.checkResourceIsReachable()) == true else { return nil }

        // 2. Localized name is standard metadata
        let name = (try? url.resourceValues(forKeys: [.localizedNameKey]))?.localizedName
                   ?? url.deletingPathExtension().lastPathComponent
        
        let path = url.path
        
        // 3. CORRECTED: Get the Bundle ID safely
        // We attempt to load the bundle non-destructively to read the identifier
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
