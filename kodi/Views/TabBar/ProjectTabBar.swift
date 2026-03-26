import SwiftUI

struct ProjectTabBar: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                ForEach(appState.repositories) { repo in
                    ProjectTab(
                        repo: repo,
                        isSelected: repo.id == appState.selectedRepositoryID,
                        changedCount: appState.repositoryViewModels[repo.id]?.changedFiles.count ?? 0,
                        onSelect: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                appState.selectedRepositoryID = repo.id
                            }
                        },
                        onClose: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                appState.removeRepository(id: repo.id)
                            }
                        }
                    )
                }
            }
        }
    }
}

struct ProjectTab: View {
    let repo: GitRepository
    let isSelected: Bool
    let changedCount: Int
    let onSelect: () -> Void
    let onClose: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "arrow.triangle.branch")
                .imageScale(.small)
                .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)

            Text(repo.displayName)
                .font(.callout)
                .lineLimit(1)

            if changedCount > 0 {
                Text("\(changedCount)")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(.fill.tertiary, in: .capsule)
            }

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 14, height: 14)
            }
            .buttonStyle(.plain)
            .opacity(isHovering || isSelected ? 1 : 0)
        }
        .padding(.leading, 10)
        .padding(.trailing, 6)
        .padding(.vertical, 5)
        .background(
            isSelected
                ? AnyShapeStyle(.tint.opacity(0.12))
                : isHovering
                    ? AnyShapeStyle(.fill.quaternary)
                    : AnyShapeStyle(.clear),
            in: .rect(cornerRadius: 6)
        )
        .contentShape(.rect(cornerRadius: 6))
        .onTapGesture(perform: onSelect)
        .onHover { isHovering = $0 }
    }
}
