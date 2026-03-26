import SwiftUI

struct FocusedRepositoryKey: FocusedValueKey {
    typealias Value = RepositoryViewModel
}

extension FocusedValues {
    var repositoryViewModel: RepositoryViewModel? {
        get { self[FocusedRepositoryKey.self] }
        set { self[FocusedRepositoryKey.self] = newValue }
    }
}
