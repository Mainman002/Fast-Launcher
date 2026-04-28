import SwiftUI
import Combine
import AppKit

@MainActor
final class LauncherModel: ObservableObject {
    @Published var apps: [AppEntry] = []
    @Published var filteredApps: [AppEntry] = []
    @Published var searchText: String = ""
    @Published var isAscending: Bool = true // 💡 New toggle state

    func toggleSortOrder() {
        isAscending.toggle()
        updateSearch(searchText) // Re-sort current view
    }

    func loadApps() {
        Task(priority: .userInitiated) {
            let scanned = AppScanner.scanApplications()
            await MainActor.run {
                self.apps = scanned
                self.updateSearch(self.searchText)
            }
        }
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
