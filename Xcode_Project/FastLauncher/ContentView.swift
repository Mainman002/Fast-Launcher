import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var model = LauncherModel()
    @FocusState private var searchFocused: Bool
    @State private var selectedIndex: Int = 0
    @State private var showSettings = false

//    private let columns = [GridItem(.adaptive(minimum: 120), spacing: 12)]
    
    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: model.gridSize), spacing: 12)]
    }
    
    private let columnsCount = 6
    private let app_version = "0.1.5"

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

    // In ContentView.swift
    private var favoritesShelf: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) { // Spacing matches the grid
                ForEach(model.favoriteApps) { app in
                    // 💡 Use the new unified ShelfCardView
                    ShelfCardView(
                        app: app,
                        iconSize: model.headerSize, // Still controlled by header slider
                        onLaunch: {
                            model.launch(app)
                            hideLauncher()
                        },
                        onRemove: {
                            withAnimation(.spring()) {
                                model.toggleFavorite(app)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
        // Set height dynamically based on the iconSize plus room for the card
        .frame(height: model.headerSize + 60)
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
                            isFavorite: model.favoritePaths.contains(app.path),
                            isHidden: model.hiddenPaths.contains(app.path), // Hook up state
                            gridSize: model.gridSize,
                            onClick: {
                                model.launch(app)
                                hideLauncher()
                            },
                            onToggleFavorite: {
                                model.toggleFavorite(app)
                            },
                            onToggleHide: { // Hook up action
                                model.toggleHide(app)
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
        ZStack {
            // 1. The CENTER section (Centered relative to the entire window)
            Text("\(model.filteredApps.count) apps")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            // 2. The LEFT and RIGHT sections
            HStack {
                // Group of 4 buttons aligned left
                HStack(spacing: 12) {
                    Button(action: { model.loadApps() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help("Refresh Apps")

                    Button(action: {
                        model.showHiddenMode.toggle()
                        model.updateSearch(model.searchText)
                    }) {
                        Image(systemName: model.showHiddenMode ? "eye.slash.fill" : "eye")
                            .foregroundColor(model.showHiddenMode ? .red : .secondary)
                    }
                    .help(model.showHiddenMode ? "Viewing Hidden Apps" : "Viewing Visible Apps")

                    Button(action: { model.toggleSortOrder() }) {
                        Image(systemName: model.isAscending ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                            .foregroundColor(model.isAscending ? .secondary : .accentColor)
                    }
                    .help(model.isAscending ? "Sorting: Ascending" : "Sorting: Descending")

                    Button(action: { showSettings.toggle() }) {
                        Image(systemName: "gearshape")
                            .foregroundColor(.secondary)
                    }
                    .popover(isPresented: $showSettings, arrowEdge: .bottom) {
                        SettingsView(model: model)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                // Version label aligned right
                Text("\(app_version)")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
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

struct ShelfItemView: View {
    let app: AppEntry
    let iconSize: Double
    let onLaunch: () -> Void
    let onRemove: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        VStack(spacing: 6) {
            Image(nsImage: app.icon)
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
            
            Text(app.name)
                .font(.system(size: max(9, iconSize * 0.25), weight: .medium))
                .lineLimit(1)
                .foregroundStyle(isHovering ? .primary : .secondary)
                .frame(width: iconSize + 30)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isHovering ? Color(NSColor.controlBackgroundColor).opacity(0.8) : Color.clear)
        )
        // 💡 The "Safe Zone" Overlay for the Star Button
        .overlay(
            ZStack(alignment: .topTrailing) {
                Button(action: onRemove) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        // Make the star slightly smaller than the grid stars
                        .font(.system(size: max(8, iconSize * 0.2)))
                        .frame(width: iconSize * 0.4, height: iconSize * 0.4)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.3))
                                .blur(radius: 1)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .opacity(isHovering ? 1 : 0)
                // Offset it slightly so it "floats" over the corner of the icon
                .offset(x: 4, y: -4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        )
        .onTapGesture { onLaunch() }
        .onHover { isHovering = $0 }
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
