import SwiftUI

struct AppCardView: View {
    let app: AppEntry
    let isSelected: Bool
    let isFavorite: Bool
    let isHidden: Bool
    let onClick: () -> Void
    let onToggleFavorite: () -> Void
    let onToggleHide: () -> Void

    @State private var hovering = false

    var body: some View {
        ZStack(alignment: .topTrailing) { // Keeping the Star top-right
            
            // 1. The Main Clickable Card Area
            VStack(spacing: 8) {
                Image(nsImage: app.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)

                Text(app.name)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(isSelected || hovering ? .primary : .secondary)
            }
            .padding(10)
            .frame(width: 120, height: 110)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(backgroundFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .onTapGesture { onClick() }
            
            // 2. The Star Button (Top-Right)
            Button(action: onToggleFavorite) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .foregroundColor(isFavorite ? .yellow : .secondary.opacity(0.5))
                    .font(.system(size: 12))
                    .padding(8)
                    .opacity(isFavorite || hovering ? 1 : 0)
            }
            .buttonStyle(.plain)

            // 3. NEW: The Visibility Toggle Button (Top-Left)
            // We use an overlay within the ZStack to pin it to the other corner
            HStack {
                // 3. Updated Visibility Toggle Button (Top-Left)
                Button(action: {
                    withAnimation { onToggleHide() }
                }) {
                    Image(systemName: isHidden ? "eye.slash.fill" : "eye")
                        .foregroundColor(isHidden ? .red : .secondary.opacity(0.5))
                        .font(.system(size: 11)) // Slightly smaller to fit better
                        .padding(8)
                        .opacity(isHidden || hovering ? 1 : 0)
                }
                .buttonStyle(.plain)
                // Use padding to nudge it away from the absolute edge
                .padding(.leading, 16)
                .padding(.top, 4)
                // This ensures it stays in the top-left corner of the ZStack
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }

            // Keep the context menu as a backup/pro feature
            .contextMenu {
                Button(isHidden ? "Unhide App" : "Hide App") {
                    withAnimation { onToggleHide() }
                }
                Divider()
                Button(isFavorite ? "Remove Favorite" : "Add Favorite") {
                    onToggleFavorite()
                }
            }
        }
        .onHover { hovering = $0 }
    }

    private var backgroundFill: Color {
        if isSelected {
            return Color.accentColor.opacity(0.15)
        } else if hovering {
            return Color(NSColor.controlBackgroundColor).opacity(0.8)
        } else {
            return Color.black.opacity(0.05)
        }
    }
}
