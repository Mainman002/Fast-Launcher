import SwiftUI

struct ShelfCardView: View {
    let app: AppEntry
    let iconSize: Double // Controlled by the 'Header Size' slider
    let onLaunch: () -> Void
    let onRemove: () -> Void

    @State private var hovering = false

    var body: some View {
        // ZStack symmetry identical to your main AppCardView
        ZStack {
            
            // 1. Unified Main Card Body (VStack + Padding + Frame)
            VStack(spacing: 6) {
                Image(nsImage: app.icon)
                    .resizable()
                    .scaledToFit()
                    // Proportional scaling for the icon
                    .frame(width: iconSize, height: iconSize)

                Text(app.name)
                    // Proportional scaling for the text
                    .font(.system(size: max(9, iconSize * 0.25), weight: .medium))
                    .lineLimit(1)
                    .foregroundStyle(hovering ? .primary : .secondary)
                    // Keep text wider than icon, limited by card size
                    .frame(width: iconSize + 30)
            }
            .padding(10)
            // Use iconSize to control the total card frame
            .frame(width: iconSize + 50, height: iconSize + 40)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundFill)
            )
            .onTapGesture { onLaunch() }
            
            // 2. The Unified Remove Button (The Safe Zone overlay)
            // This replicates the grid's star button alignment and scaling.
            .overlay(
                ZStack {
                    Button(action: onRemove) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            // Proportional scaling for the star
                            .font(.system(size: max(10, iconSize * 0.25)))
                            // Proportional hit-box and centering
                            .frame(width: iconSize * 0.5, height: iconSize * 0.5)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    // Same visibility logic as the main grid stars
                    .opacity(hovering ? 1 : 0)
                }
                // Lock the small invisible container to the top-right
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                // Use relative padding to keep it tight, regardless of scaling
                .padding(.trailing, iconSize * 0.05)
                .padding(.top, iconSize * 0.05)
            )
        }
        // Context menu backup (like the main cards, but only 'Remove')
        .contextMenu {
            Button("Remove Favorite") { onRemove() }
        }
        .onHover { hovering = $0 }
    }

    // Unified background hover logic
    private var backgroundFill: Color {
        if hovering {
            // Using a slightly more opaque background for clarity on the glass
            return Color(NSColor.controlBackgroundColor).opacity(0.8)
        } else {
            return Color.black.opacity(0.05)
        }
    }
}
