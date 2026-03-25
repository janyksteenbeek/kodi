import SwiftUI

struct ProjectTabBar: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(appState.repositories) { repo in
                    ProjectTab(
                        repo: repo,
                        isSelected: repo.id == appState.selectedRepositoryID,
                        changedCount: appState.repositoryViewModels[repo.id]?.changedFiles.count ?? 0
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            appState.selectedRepositoryID = repo.id
                        }
                    }
                }
            }
        }
    }
}

struct ProjectTab: View {
    let repo: GitRepository
    let isSelected: Bool
    let changedCount: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "folder.fill")
                .imageScale(.small)
                .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)

            Text(repo.displayName)
                .font(.callout)
                .lineLimit(1)

            if changedCount > 0 {
                Text("\(changedCount)")
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(.tint.opacity(0.8), in: .capsule)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            isSelected
                ? AnyShapeStyle(.tint.opacity(0.12))
                : AnyShapeStyle(.clear),
            in: .capsule
        )
        .contentShape(.capsule)
    }
}
