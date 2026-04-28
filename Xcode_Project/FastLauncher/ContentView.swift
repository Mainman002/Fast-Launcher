import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var model = LauncherModel()
    @FocusState private var searchFocused: Bool
    @State private var selectedIndex: Int = 0

    private let columns = [GridItem(.adaptive(minimum: 120), spacing: 12)]
    private let columnsCount = 6

    var body: some View {
        VStack(spacing: 0) {
            searchBar
                .padding(.bottom, 10)
            
            // 💡 The Favorites Shelf
            if !model.favoriteApps.isEmpty {
                favoritesShelf
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
                
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.horizontal, 20)
            }

            resultsGrid
            
//            Divider()
//                .background(Color.white.opacity(0.1))
//                .padding(.horizontal, 20)
            
            bottomBar
        }
        .frame(width: 900, height: 600)
        .background(glassBackground) // Moved to a helper property for clarity
        .padding(12)
        .onAppear(perform: setupOnAppear)
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            focusSearch()
        }
        .onExitCommand { hideLauncher() }
        .background(keyHandler)
    }

    // MARK: - Background Component
    
    private var glassBackground: some View {
        ZStack {
            VisualEffectView()
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            
            // The "Glass Border" highlight
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.4), .white.opacity(0.1), .black.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    }

    // MARK: - Favorites Shelf

    private var favoritesShelf: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(model.favoriteApps) { app in
                    VStack(spacing: 6) {
                        // Using your existing icon logic from the model
                        Image(nsImage: app.icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                            .onTapGesture {
                                model.launch(app)
                                hideLauncher()
                            }
                        
                        Text(app.name)
                            .font(.system(size: 10, weight: .medium))
                            .lineLimit(1)
                            .foregroundStyle(.secondary)
                            .frame(width: 70)
                    }
                    .help(app.path)
                    .contextMenu {
                        Button("Remove from Favorites") {
                            withAnimation(.spring()) {
                                model.toggleFavorite(app)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 25)
            .padding(.vertical, 12)
        }
        .frame(height: 85)
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
                        // 💡 Updated this call to include the new parameters
                        AppCardView(
                            app: app,
                            isSelected: index == selectedIndex,
                            isFavorite: model.favoritePaths.contains(app.path), // Pass current status
                            onClick: {
                                model.launch(app)
                                hideLauncher()
                            },
                            onToggleFavorite: {
                                // Tell the model to toggle the favorite status
                                model.toggleFavorite(app)
                            }
                        )
                        .id(index)
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
            
            Spacer()
            
            Text("0.1.2")
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
        view.material = .hudWindow // This provides that high-quality Spotlight blur
        view.autoresizingMask = [.width, .height]
        return view
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
