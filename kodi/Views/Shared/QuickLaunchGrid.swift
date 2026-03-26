import SwiftUI

struct QuickLaunchIcon: View {
    let item: QuickLaunchItem
    var size: CGFloat = 20

    var body: some View {
        if item.isCustomImage {
            Image(item.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
        } else {
            Image(systemName: item.icon)
                .font(.system(size: size, weight: .medium))
        }
    }
}

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
                QuickLaunchIcon(item: item, size: 20)
                    .foregroundStyle(item.displayColor)

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
            .frame(width: 100, height: 85)
            .background(
                isHovering ? AnyShapeStyle(.fill.quaternary) : AnyShapeStyle(.fill.quinary),
                in: .rect(cornerRadius: 10)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: 0.1), value: isHovering)
    }
}
