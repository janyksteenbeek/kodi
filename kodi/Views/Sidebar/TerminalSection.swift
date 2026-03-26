import SwiftUI

struct TerminalSection: View {
    @Bindable var viewModel: RepositoryViewModel

    var body: some View {
        Section {
            ForEach(viewModel.terminalSessions) { session in
                TerminalSessionRow(session: session, viewModel: viewModel)
                    .tag(RepositoryViewModel.terminalTagPrefix + session.id.uuidString)
            }

            Button {
                viewModel.createTerminalInPanel()
            } label: {
                Label("Open Terminal", systemImage: "plus")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        } header: {
            Text("Terminals")
        }
    }
}

struct QuickLaunchBar: View {
    @Bindable var viewModel: RepositoryViewModel
    private let items = QuickLaunchItem.loadItems()

    var body: some View {
        HStack(spacing: 6) {
            ForEach(items) { item in
                Button {
                    viewModel.launchQuickItem(item)
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: item.icon)
                            .font(.system(size: 13, weight: .medium))
                        Text(item.name)
                            .font(.system(size: 9, weight: .medium))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(item.displayColor.opacity(0.12), in: .rect(cornerRadius: 6))
                    .foregroundStyle(item.displayColor)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}
