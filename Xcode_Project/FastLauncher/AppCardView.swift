import SwiftUI

struct AppCardView: View {
    let app: AppEntry
    let isSelected: Bool
    let isFavorite: Bool // Pass this in from the parent
    let onClick: () -> Void
    let onToggleFavorite: () -> Void // Callback for the star

    @State private var hovering = false

    var body: some View {
        // Use a container instead of a top-level Button
        // so we can have a separate button for the star.
        ZStack(alignment: .topTrailing) {
            
            // 1. The Main Clickable Card Area
            VStack(spacing: 8) {
                Image(nsImage: app.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48) // Slightly smaller icons feel more "pro"

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
            // Handle the click on the whole card
            .onTapGesture { onClick() }
            
            // 2. The Star Button (Overlayed on top)
            Button(action: onToggleFavorite) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .foregroundColor(isFavorite ? .yellow : .secondary.opacity(0.5))
                    .font(.system(size: 12))
                    .padding(8)
                    // Only show the un-filled star when hovering to keep it clean
                    .opacity(isFavorite || hovering ? 1 : 0)
            }
            .buttonStyle(.plain)
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
