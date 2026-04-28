import SwiftUI

struct AppCardView: View {

    let app: AppEntry
    let isSelected: Bool // New property to track keyboard selection
    let onClick: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: {
            onClick()
        }) {
            VStack(spacing: 8) {
                Image(nsImage: app.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)

                Text(app.name)
                    .font(.system(size: 12))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .padding(10)
            .frame(width: 120, height: 120)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(backgroundFill) // Simplified fill logic
            )
            .overlay(
                // Added a stroke to make the selection pop on macOS
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2.5)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovering in
            hovering = isHovering
        }
    }

    // Helper to determine the background color based on interaction
    private var backgroundFill: Color {
        if hovering || isSelected {
            return Color(NSColor.controlBackgroundColor)
        } else {
            return Color(NSColor.windowBackgroundColor).opacity(0.4)
        }
    }
}
