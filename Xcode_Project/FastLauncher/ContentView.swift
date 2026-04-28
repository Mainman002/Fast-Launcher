import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var model = LauncherModel()
    @FocusState private var searchFocused: Bool
    @State private var selectedIndex: Int = 0

    private let columns = [
        GridItem(.adaptive(minimum: 120), spacing: 12)
    ]
    
    private let columnsCount = 6

    var body: some View {
        VStack(spacing: 0) { // Set spacing to 0 to avoid gaps in the transparency
            searchBar
                .padding(.bottom, 10)
            
            Divider()
                .opacity(0.2) // Barely visible line
            
            resultsGrid
            
            bottomBar
                .padding(.top, 10)
        }
        .frame(width: 900, height: 600)
        .background(
            ZStack {
                VisualEffectView()
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                
                // Subtle glass border
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
            }
        )
        .padding(12)
        .onAppear(perform: setupOnAppear)
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            focusSearch()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)) { _ in
            hideLauncher()
        }
        .onExitCommand { hideLauncher() }
        .background(keyHandler)
    }

    // MARK: - Sub-Views

    private var searchBar: some View {
        TextField("Search apps...", text: Binding(
            get: { model.searchText },
            set: {
                model.updateSearch($0)
                selectedIndex = 0
            }
        ))
        .textFieldStyle(.roundedBorder)
        .font(.system(size: 18))
        .focused($searchFocused)
        .padding(.horizontal, 12)
        .padding(.top, 14)
        .onSubmit { launchSelected() }
    }

    private var resultsGrid: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(Array(model.filteredApps.enumerated()), id: \.offset) { index, app in
                        AppCardView(app: app, isSelected: index == selectedIndex) {
                            model.launch(app)
                            hideLauncher()
                        }
                        .id(index) // This matches your ScrollViewReader proxy
                    }
                }
                .padding()
                .scrollContentBackground(.hidden)
            }
            .onChange(of: selectedIndex) { _, newValue in
                withAnimation(.easeOut(duration: 0.12)) {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Button(action: { model.loadApps() }) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.plain)
            .help("Refresh Apps")

            // 💡 The new Sort Toggle Button
            Button(action: { model.toggleSortOrder() }) {
                Image(systemName: model.isAscending ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                    .foregroundColor(model.isAscending ? .secondary : .accentColor)
            }
            .buttonStyle(.plain)
            .help(model.isAscending ? "Sorting: Ascending" : "Sorting: Descending")

            Spacer()
            
            Text("\(model.filteredApps.count) apps")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }

    private var keyHandler: some View {
        KeyEventHandlingView(
            onEscape: { hideLauncher() },
            onUpArrow: { moveSelectionUp() },
            onDownArrow: { moveSelectionDown() },
            onEnter: { launchSelected() }
        )
    }

    // MARK: - Logic Helpers

    private func setupOnAppear() {
        model.loadApps()
        focusSearch()
    }

    private func focusSearch() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            searchFocused = true
        }
    }

    private func moveSelectionDown() {
        if model.filteredApps.isEmpty { return }
        let nextIndex = selectedIndex + columnsCount
        selectedIndex = min(nextIndex, model.filteredApps.count - 1)
    }

    private func moveSelectionUp() {
        if model.filteredApps.isEmpty { return }
        let nextIndex = selectedIndex - columnsCount
        selectedIndex = max(nextIndex, 0)
    }

    private func launchSelected() {
        guard !model.filteredApps.isEmpty else { return }
        let app = model.filteredApps[selectedIndex]
        model.launch(app)
        hideLauncher()
    }

    private func hideLauncher() {
        NSApp.windows.first?.orderOut(nil)
    }
}

struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.state = .active
        view.material = .hudWindow // 💡 This provides that high-quality Spotlight blur
        return view
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
