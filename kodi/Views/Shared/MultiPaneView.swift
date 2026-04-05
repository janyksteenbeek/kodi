import SwiftUI

struct MultiPaneView<Item: Identifiable, Header: View, Content: View>: View {
    let items: [Item]
    let layout: PaneLayout
    @ViewBuilder let header: (Item) -> Header
    @ViewBuilder let content: (Item) -> Content
    let onClose: ((Item) -> Void)?

    private var showPaneHeaders: Bool { items.count > 1 }

    var body: some View {
        switch layout {
        case .horizontal:
            linearLayout(isHorizontal: true)
        case .vertical:
            linearLayout(isHorizontal: false)
        case .grid:
            gridLayout()
        }
    }

    @ViewBuilder
    private func linearLayout(isHorizontal: Bool) -> some View {
        let stack = isHorizontal
            ? AnyLayout(HStackLayout(spacing: 0))
            : AnyLayout(VStackLayout(spacing: 0))

        stack {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                if index > 0 {
                    Rectangle()
                        .fill(Color(nsColor: .separatorColor))
                        .frame(width: isHorizontal ? 1 : nil, height: isHorizontal ? nil : 1)
                }
                paneView(item: item)
            }
        }
    }

    @ViewBuilder
    private func gridLayout() -> some View {
        let (rows, cols) = Self.gridDimensions(count: items.count)

        VStack(spacing: 0) {
            ForEach(0..<rows, id: \.self) { row in
                if row > 0 {
                    Rectangle()
                        .fill(Color(nsColor: .separatorColor))
                        .frame(height: 1)
                }
                HStack(spacing: 0) {
                    ForEach(0..<cols, id: \.self) { col in
                        let index = row * cols + col
                        if col > 0 {
                            Rectangle()
                                .fill(Color(nsColor: .separatorColor))
                                .frame(width: 1)
                        }
                        if index < items.count {
                            paneView(item: items[index])
                        } else {
                            Color.clear
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func paneView(item: Item) -> some View {
        VStack(spacing: 0) {
            if showPaneHeaders {
                HStack(spacing: 4) {
                    header(item)
                    Spacer()
                    if let onClose {
                        Button {
                            onClose(item)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.caption2)
                        }
                        .buttonStyle(.borderless)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color(nsColor: .controlBackgroundColor))

                Divider()
            }

            content(item)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    static func gridDimensions(count: Int) -> (rows: Int, cols: Int) {
        switch count {
        case 1: return (1, 1)
        case 2: return (1, 2)
        case 3, 4: return (2, 2)
        case 5, 6: return (2, 3)
        case 7, 8: return (2, 4)
        default:
            let cols = Int(ceil(sqrt(Double(count))))
            let rows = Int(ceil(Double(count) / Double(cols)))
            return (rows, cols)
        }
    }
}
