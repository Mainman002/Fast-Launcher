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

    init() {
        loadFavorites()
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
            let scanned = AppScanner.scanApplications()
            
            await MainActor.run {
                self.apps = scanned.sorted { smartSort($0.name, $1.name) }
                
                // 💡 Safety Check: Remove favorites that no longer exist on disk
                let validPaths = Set(scanned.map { $0.path })
                let orphanedFavorites = self.favoritePaths.subtracting(validPaths)
                
                if !orphanedFavorites.isEmpty {
                    self.favoritePaths.formIntersection(validPaths)
                    self.saveFavorites()
                    print("Cleaned up \(orphanedFavorites.count) missing apps from favorites.")
                }
                
                self.updateSearch(self.searchText)
            }
        }
    }
    
    var favoriteApps: [AppEntry] {
        apps.filter { favoritePaths.contains($0.path) }
    }

    func updateSearch(_ text: String) {
        searchText = text
        let query = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        if query.isEmpty {
            filteredApps = apps.sorted { smartSort($0.name, $1.name) }
            return
        }

        let scored: [(AppEntry, Int)] = apps.compactMap { app in
            if let score = FuzzySearch.score(query: query, target: app.name) {
                if score > 50 { return (app, score) }
            }
            return nil
        }

        filteredApps = scored.sorted { a, b in
            let scoreA = a.1 / 100
            let scoreB = b.1 / 100
            if scoreA != scoreB { return scoreA > scoreB }
            return smartSort(a.0.name, b.0.name)
        }.map { $0.0 }
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
