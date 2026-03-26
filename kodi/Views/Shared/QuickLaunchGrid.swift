import SwiftUI

struct QuickLaunchGrid: View {
    let onLaunch: (QuickLaunchItem) -> Void
    private let items = QuickLaunchItem.loadItems()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick Launch")
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                ForEach(items) { item in
                    QuickLaunchCard(item: item) {
                        onLaunch(item)
                    }
                }
            }
        }
    }
}

private struct QuickLaunchCard: View {
    let item: QuickLaunchItem
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(item.displayColor.gradient.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: item.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(item.displayColor)
                }

                VStack(spacing: 2) {
                    Text(item.name)
                        .font(.callout.weight(.medium))
                        .lineLimit(1)

                    if !item.command.isEmpty {
                        Text(item.command)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }
            }
            .frame(width: 100, height: 95)
            .background(
                .ultraThinMaterial,
                in: .rect(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(.quaternary, lineWidth: 0.5)
            )
            .scaleEffect(isHovering ? 1.04 : 1.0)
            .shadow(color: isHovering ? item.displayColor.opacity(0.2) : .clear, radius: 8)
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: 0.15), value: isHovering)
    }
}
