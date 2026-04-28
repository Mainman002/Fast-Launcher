import SwiftUI

struct AppCardView: View {
    let app: AppEntry
    let isSelected: Bool
    let isFavorite: Bool
    let isHidden: Bool
    let gridSize: Double
    let onClick: () -> Void
    let onToggleFavorite: () -> Void
    let onToggleHide: () -> Void

    @State private var hovering = false

    var body: some View {
        // 1. Main Card Body
        VStack(spacing: 8) {
            Image(nsImage: app.icon)
                .resizable()
                .scaledToFit()
                .frame(width: gridSize * 0.4, height: gridSize * 0.4)

            Text(app.name)
                .font(.system(size: gridSize * 0.09, weight: .medium))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundStyle(isSelected || hovering ? .primary : .secondary)
        }
        .padding(10)
        .frame(width: gridSize, height: gridSize * 0.9)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(backgroundFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        // 2. The Button Layer (The "Safe Zone")
        .overlay(
            ZStack {
                // Star Button
                Button(action: onToggleFavorite) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundColor(isFavorite ? .yellow : .secondary.opacity(0.5))
                        .font(.system(size: max(10, gridSize * 0.09)))
                        .frame(width: gridSize * 0.25, height: gridSize * 0.25)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .opacity(isFavorite || hovering ? 1 : 0)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

                // Visibility Button
                Button(action: { withAnimation { onToggleHide() } }) {
                    Image(systemName: isHidden ? "eye.slash.fill" : "eye")
                        .foregroundColor(isHidden ? .red : .secondary.opacity(0.5))
                        .font(.system(size: max(10, gridSize * 0.09)))
                        .frame(width: gridSize * 0.25, height: gridSize * 0.25)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .opacity(isHidden || hovering ? 1 : 0)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .padding(4) // Keeps buttons from hugging the literal pixel-edge
        )
        .onTapGesture { onClick() }
        .onHover { hovering = $0 }
        .contextMenu {
            Button(isHidden ? "Unhide App" : "Hide App") { withAnimation { onToggleHide() } }
            Divider()
            Button(isFavorite ? "Remove Favorite" : "Add Favorite") { onToggleFavorite() }
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
