import SwiftUI
import Combine
import AppKit

@MainActor
final class LauncherModel: ObservableObject {

    @Published var apps: [AppEntry] = []
    @Published var filteredApps: [AppEntry] = []
    @Published var searchText: String = ""

    private var searchTask: Task<Void, Never>?

    func loadApps() {
        Task(priority: .userInitiated) {
            let scanned = AppScanner.scanApplications()
            
            await MainActor.run {
                self.apps = scanned
                // This ensures that even if you have text in the search box,
                // the list updates immediately after the scan.
                self.updateSearch(self.searchText)
            }
        }
    }

    func updateSearch(_ text: String) {
        searchText = text
        
        // Use trimmingCharacters(in: .whitespacesAndNewlines)
        // to clean the edges, but keep the spaces in the middle!
        let query = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        if query.isEmpty {
            filteredApps = apps
            return
        }

        let scored: [(AppEntry, Int)] = apps.compactMap { app in
            if let score = FuzzySearch.score(query: query, target: app.name) {
                // Keep a threshold to filter out the "Angry IP Scanner" noise
                if score > 50 {
                    return (app, score)
                }
            }
            return nil
        }

        filteredApps = scored
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
    }

    func launch(_ app: AppEntry) {
        let url = URL(fileURLWithPath: app.path)
        NSWorkspace.shared.open(url)
    }
}
