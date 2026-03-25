import SwiftUI

struct StatusBadge: View {
    let status: ChangedFile.FileStatus

    var body: some View {
        Text(status.rawValue)
            .font(.caption2.bold().monospaced())
            .foregroundStyle(status.color)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(status.color.opacity(0.15), in: .rect(cornerRadius: 4))
    }
}
