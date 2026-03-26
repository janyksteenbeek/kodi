import SwiftUI

struct StatusBadge: View {
    let status: ChangedFile.FileStatus

    var body: some View {
        Circle()
            .fill(status.color)
            .frame(width: 7, height: 7)
            .help(status.displayName)
    }
}
