import SwiftUI
import Combine
import AppKit

@MainActor
final class LauncherModel: ObservableObject {
    @Published var apps: [AppEntry] = []
    @Published var filteredApps: [AppEntry] = []
    @Published var favoritePaths: Set<String> = [] // Persistent store
    private let favoritesKey = "user_favorites_list"
    @Published var searchText: String = ""
    @Published var isAscending: Bool = true // New toggle state
    @Published var hiddenPaths: Set<String> = []
    @Published var showHiddenMode: Bool = false // Toggle state
    
    @AppStorage("custom_paths") var customPaths: String = "/Applications" // Stored as comma-separated
    @AppStorage("grid_size") var gridSize: Double = 110.0
    @AppStorage("header_size") var headerSize: Double = 40.0
    
    private let hiddenKey = "user_hidden_list"

    var directoryList: [String] {
        customPaths.components(separatedBy: ",").filter { !$0.isEmpty }
    }

    func addPath(_ path: String) {
        var paths = directoryList
        if !paths.contains(path) {
            paths.append(path)
            customPaths = paths.joined(separator: ",")
            loadApps() // Rescan with new path
        }
    }

    func removePath(_ path: String) {
        let paths = directoryList.filter { $0 != path }
        customPaths = paths.joined(separator: ",")
        loadApps()
    }
    
    private func loadHidden() {
        let saved = UserDefaults.standard.stringArray(forKey: hiddenKey) ?? []
        self.hiddenPaths = Set(saved)
    }

    init() {
        loadFavorites()
        loadHidden()
        print("DEBUG: Active Directory List: \(directoryList)")
    }
    
    func toggleHide(_ app: AppEntry) {
        if hiddenPaths.contains(app.path) {
            hiddenPaths.remove(app.path)
        } else {
            hiddenPaths.insert(app.path)
        }
        saveHidden()
        updateSearch(searchText) // Refresh the list immediately
    }

    private func saveHidden() {
        UserDefaults.standard.set(Array(hiddenPaths), forKey: hiddenKey)
    }

    // MARK: - Favorites Logic
    
    func toggleFavorite(_ app: AppEntry) {
        if favoritePaths.contains(app.path) {
            favoritePaths.remove(app.path)
        } else {
            favoritePaths.insert(app.path)
        }
        saveFavorites()
    }
    
    func resetPaths() {
        customPaths = "/Applications,/System/Applications,/Users/\(NSUserName())/Applications"
        loadApps()
    }

    private func saveFavorites() {
        let array = Array(favoritePaths)
        UserDefaults.standard.set(array, forKey: favoritesKey)
    }

    private func loadFavorites() {
        let saved = UserDefaults.standard.stringArray(forKey: favoritesKey) ?? []
        self.favoritePaths = Set(saved)
    }
    
    func toggleSortOrder() {
        isAscending.toggle()
        updateSearch(searchText) // Re-sort current view
    }

    func loadApps() {
        Task(priority: .userInitiated) {
            var allScanned: [AppEntry] = []
            var seenPaths = Set<String>() // Local tracker for this scan session
            
            // 1. Scan the custom/default directory list
            for path in directoryList {
                let appsInPath = AppScanner.scanApplications(at: path, seenPaths: &seenPaths)
                allScanned.append(contentsOf: appsInPath)
            }
            
            await MainActor.run {
                // 2. Sort according to your smartSort logic
                self.apps = allScanned.sorted { smartSort($0.name, $1.name) }
                
                // 3. Validation and UI refresh
                let validPaths = Set(self.apps.map { $0.path })
                self.favoritePaths.formIntersection(validPaths)
                self.updateSearch(self.searchText)
            }
        }
    }
    
    var favoriteApps: [AppEntry] {
        apps.filter { favoritePaths.contains($0.path) }
    }

    func updateSearch(_ text: String) {
        self.searchText = text
        let query = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // 1. First, define our "Visibility Pool"
        let visiblePool = apps.filter { app in
            if showHiddenMode {
                return hiddenPaths.contains(app.path)
            } else {
                return !hiddenPaths.contains(app.path)
            }
        }

        // 2. Apply Search Filter
        if query.isEmpty {
            // Just sort the current pool
            self.filteredApps = visiblePool.sorted { smartSort($0.name, $1.name) }
        } else {
            // Fuzzy search within the current pool only
            let scored: [(AppEntry, Int)] = visiblePool.compactMap { app in
                if let score = FuzzySearch.score(query: query, target: app.name) {
                    if score > 50 { return (app, score) }
                }
                return nil
            }

            self.filteredApps = scored.sorted { a, b in
                let scoreA = a.1 / 100
                let scoreB = b.1 / 100
                if scoreA != scoreB { return scoreA > scoreB }
                return smartSort(a.0.name, b.0.name)
            }.map { $0.0 }
        }
    }

    private func smartSort(_ nameA: String, _ nameB: String) -> Bool {
        let isSameFamily = nameA.prefix(3).lowercased() == nameB.prefix(3).lowercased()
        
        if isSameFamily {
            // When Ascending: Newest first (Descending version)
            // When Descending: Oldest first (Ascending version)
            return isAscending
                ? nameA.localizedStandardCompare(nameB) == .orderedDescending
                : nameA.localizedStandardCompare(nameB) == .orderedAscending
        } else {
            // Global List: A-Z vs Z-A
            return isAscending
                ? nameA.localizedStandardCompare(nameB) == .orderedAscending
                : nameA.localizedStandardCompare(nameB) == .orderedDescending
        }
    }

    func launch(_ app: AppEntry) {
        let url = URL(fileURLWithPath: app.path)
        NSWorkspace.shared.open(url)
    }
}
